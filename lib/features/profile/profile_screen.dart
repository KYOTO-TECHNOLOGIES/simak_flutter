import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';
import 'package:uae_ecom_project/features/auth/widgets/unified_auth_form.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/orders/screens/order_detail_screen.dart';

import 'package:uae_ecom_project/features/auth/widgets/otp_verification_dialog.dart';
import 'package:uae_ecom_project/features/auth/widgets/add_address_dialog.dart';
import 'package:uae_ecom_project/features/profile/screens/notification_screen.dart';
import 'package:uae_ecom_project/features/profile/screens/referral_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedSection = 0; // 0: Personal Info, 1: My Orders, 2: Addresses
  bool _isEditing = false;

  // Edit controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  String? _selectedGender;
  DateTime? _selectedDob;
  String _preferredLanguageCode = 'en';

  final ScrollController _tabsScrollController = ScrollController();
  bool _showTabsArrow = true;

  static const Map<String, String> _languageLabels = {
    'en': 'English',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'cn': 'Chinese',
  };

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  static const Map<String, String> _editableLanguageLabels = {
    'en': 'English',
    'ar': 'Arabic',
    'cn': 'Chinese',
  };

  String _languageDisplay(String code) =>
      _languageLabels[code] ?? code.toUpperCase();

  Widget _getLanguageIcon(String code, {double size = 18}) {
    switch (code) {
      case 'en': return Text('🇺🇸', style: TextStyle(fontSize: size));
      case 'ar': return Text('🇦🇪', style: TextStyle(fontSize: size));
      case 'cn': return Text('🇨🇳', style: TextStyle(fontSize: size));
      default: return Icon(Icons.language_outlined, size: size, color: AppColors.actionBlue);
    }
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    
    _tabsScrollController.addListener(() {
      if (_tabsScrollController.hasClients) {
        final show = _tabsScrollController.offset < _tabsScrollController.position.maxScrollExtent - 5;
        if (show != _showTabsArrow) {
          setState(() => _showTabsArrow = show);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().refreshProfile();
      if (_tabsScrollController.hasClients) {
        setState(() {
          _showTabsArrow = _tabsScrollController.position.maxScrollExtent > 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tabsScrollController.dispose();
    super.dispose();
  }

  void _startEditing(UserModel user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    
    // Normalize gender to codes (M/F/O)
    final gender = user.profile?.gender;
    if (gender != null) {
      if (gender.toLowerCase().startsWith('m')) _selectedGender = 'M';
      else if (gender.toLowerCase().startsWith('f')) _selectedGender = 'F';
      else if (gender.toLowerCase().startsWith('o')) _selectedGender = 'O';
      else _selectedGender = gender;
    } else {
      _selectedGender = null;
    }

    if (user.profile?.dateOfBirth != null &&
        (user.profile!.dateOfBirth ?? '').isNotEmpty) {
      _selectedDob = DateTime.tryParse(user.profile!.dateOfBirth!);
    } else {
      _selectedDob = null;
    }
    _preferredLanguageCode = user.profile?.preferredLanguage ?? 'en';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthController>();
    final Map<String, dynamic> data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
    };

    // Only include profile fields that have actual values
    final profileData = <String, dynamic>{};
    if (_selectedGender != null && _selectedGender!.isNotEmpty) {
      profileData['gender'] = _selectedGender;
    }
    if (_selectedDob != null) {
      profileData['date_of_birth'] = _selectedDob!.toIso8601String().split('T').first;
    }
    profileData['preferred_language'] = _preferredLanguageCode;

    if (profileData.isNotEmpty) {
      data['profile'] = profileData;
    }

    final success = await auth.updateProfile(data);
    if (!mounted) return;

    if (success) {
      context.read<LanguageProvider>().setLocale(_preferredLanguageCode);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'profile_updated')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? tr(context, 'profile_update_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) {
            return _NotLoggedInView(theme: theme);
          }

          final user = auth.currentUser!;
          return RefreshIndicator(
            onRefresh: () async {
              if (_selectedSection == 1) {
                await context.read<OrderController>().fetchMyOrders();
              } else if (_selectedSection == 2) {
                await context.read<AddressController>().fetchAddresses();
              } else {
                await auth.refreshProfile();
              }
            },
            color: AppColors.actionBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, theme),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSummaryCard(context, user, theme),
                      _buildSectionTabs(context, theme),
                      _buildContent(context, user, theme),
                      // Bottom padding to avoid content being hidden behind floating nav bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      floating: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        tr(context, 'profile'),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          );
        },
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: theme.colorScheme.onSurface),
          onPressed: () => _showLogoutConfirmation(context),
        ),
      ],
    );
  }

  Widget _buildUserSummaryCard(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    const isDark = false;
    final initials = _getInitials(user);
    final displayName =
        user.fullName.trim().isNotEmpty ? user.fullName : 'Account Member';
    final phone = user.phoneNumber ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00B4DB),
                  Color(0xFF0083B0),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0083B0),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 18, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(UserModel user) {
    if (user.firstName.isNotEmpty && user.lastName.isNotEmpty) {
      return '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();
    }
    if (user.firstName.isNotEmpty) return user.firstName.substring(0, 1).toUpperCase();
    if (user.email.isNotEmpty) return user.email.substring(0, 1).toUpperCase();
    return 'AM';
  }

  Widget _buildSectionTabs(BuildContext context, ThemeData theme) {
    final sections = [
      (Icons.person_outline, tr(context, 'personal_info')),
      (Icons.shopping_bag_outlined, tr(context, 'my_orders')),
      (Icons.location_on_outlined, tr(context, 'my_addresses')),
      (Icons.rate_review_outlined, tr(context, 'my_reviews')),
      (Icons.card_giftcard_outlined, tr(context, 'referrals')),
    ];

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SingleChildScrollView(
          controller: _tabsScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(sections.length, (i) {
              final (icon, label) = sections[i];
              final isSelected = _selectedSection == i;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                onTap: () {
                  setState(() => _selectedSection = i);
                  if (i == 1) {
                    context.read<OrderController>().fetchMyOrders();
                  } else if (i == 2) {
                    context.read<AddressController>().fetchAddresses();
                  } else if (i == 3) {
                    final user = context.read<AuthController>().currentUser;
                    if (user != null && user.id != null) {
                      context.read<OrderController>().fetchUserReviews(user.id!);
                    }
                  }
                },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.actionBlue.withOpacity(0.12)
                          : (theme.brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.actionBlue
                            : theme.dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.actionBlue
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.actionBlue
                                : theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_showTabsArrow)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.actionBlue.withOpacity(0.8)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    if (_selectedSection == 0) {
      return _buildPersonalInfoSection(context, user, theme);
    }
    if (_selectedSection == 1) {
      // Refresh orders when entering the section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = context.read<OrderController>();
        if (!controller.isLoading) {
          controller.fetchMyOrders();
        }
      });
      return _buildMyOrdersSection(context, theme);
    }
    if (_selectedSection == 2) {
      return _buildAddressesSection(context, theme);
    }
    if (_selectedSection == 3) {
      // Refresh reviews when entering the section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = context.read<OrderController>();
        if (!controller.isLoading && user.id != null) {
          controller.fetchUserReviews(user.id!);
        }
      });
      return _buildMyReviewsSection(context, theme);
    }

    return const ReferralScreen();
  }

  Widget _buildPersonalInfoSection(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    const isDark = false;
    final profile = user.profile;
    final hasEmail = user.email.trim().isNotEmpty;
    final hasPhone = (user.phoneNumber ?? '').trim().isNotEmpty;
    final dobDisplay = profile?.dateOfBirth != null && profile!.dateOfBirth!.isNotEmpty
        ? _formatDate(profile.dateOfBirth!)
        : '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.actionBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'personal_info'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(context, 'profile_info_subtitle'),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => _startEditing(user),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(tr(context, 'edit')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.actionBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                )
              else
                TextButton(
                  onPressed: _cancelEditing,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(tr(context, 'cancel')),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // First name & Last name
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: _buildEditableTextField(
                    context,
                    tr(context, 'first_name_label'),
                    _firstNameController,
                    theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEditableTextField(
                    context,
                    tr(context, 'last_name_label'),
                    _lastNameController,
                    theme,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoField(
                    context,
                    tr(context, 'first_name_label'),
                    user.firstName.trim().isEmpty ? '—' : user.firstName,
                    theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoField(
                    context,
                    tr(context, 'last_name_label'),
                    user.lastName.trim().isEmpty ? '—' : user.lastName,
                    theme,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Email field with Add/Edit button
          _buildEmailField(context, user, theme),
          const SizedBox(height: 20),

          // Phone field with verification
          _buildPhoneField(context, user, theme),
          const SizedBox(height: 20),

          // Gender
          if (_isEditing) ...[
            _buildGenderDropdown(context, theme),
          ] else ...[
            _buildInfoField(
              context,
              tr(context, 'gender_label'),
              _getGenderLabel(profile?.gender),
              theme,
            ),
          ],
          const SizedBox(height: 20),

          // Date of Birth
          if (_isEditing) ...[
            _buildDobPicker(context, theme),
          ] else ...[
            _buildInfoFieldWithIcon(
              context,
              tr(context, 'profile_dob_label'),
              dobDisplay,
              Icons.calendar_today_outlined,
              theme,
            ),
          ],
          const SizedBox(height: 20),

          // Preferred Language
          if (_isEditing) ...[
            _buildLanguageDropdown(context, theme),
          ] else ...[
            _buildInfoFieldWithWidgetIcon(
              context,
              tr(context, 'profile_lang_label'),
              _languageDisplay(profile?.preferredLanguage ?? 'en'),
              _getLanguageIcon(profile?.preferredLanguage ?? 'en', size: 18),
              theme,
            ),
          ],

          // Save button in edit mode
          if (_isEditing) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<AuthController>(
                builder: (context, auth, _) {
                  return ElevatedButton(
                    onPressed: auth.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.actionBlue.withOpacity(0.4),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            tr(context, 'save_changes'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Editable Fields ───────────────────────────────────────────

  Widget _buildEditableTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.actionBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'gender_label'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: Text(tr(context, 'select_gender_hint'), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
          items: [
            DropdownMenuItem(value: 'M', child: Text(tr(context, 'Male'))),
            DropdownMenuItem(value: 'F', child: Text(tr(context, 'Female'))),
            DropdownMenuItem(value: 'O', child: Text(tr(context, 'Other'))),
          ],
          onChanged: (v) => setState(() => _selectedGender = v),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.actionBlue, width: 1.5),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDobPicker(BuildContext context, ThemeData theme) {
    final displayText = _selectedDob != null
        ? _formatDate(_selectedDob!.toIso8601String())
        : 'Select Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'profile_dob_label'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initialDate =
                _selectedDob ?? DateTime(now.year - 18, now.month, now.day);
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: now,
            );
            if (picked != null) {
              setState(() => _selectedDob = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: displayText == 'Select Date'
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'profile_lang_label'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _preferredLanguageCode,
          items: _editableLanguageLabels.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      _getLanguageIcon(e.key),
                      const SizedBox(width: 12),
                      Text(e.value),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _preferredLanguageCode = v);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.actionBlue.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.actionBlue, width: 1.5),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ),
      ],
    );
  }

  // ─── Email Field with Add/Edit ─────────────────────────────────

  Widget _buildEmailField(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    final hasEmail = user.email.trim().isNotEmpty;
    final isVerified = user.isEmailVerified;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'email_address_label'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Text(
                  hasEmail ? user.email : '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasEmail
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _showVerifyEmailDialog(context, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hasEmail ? tr(context, 'change_email_btn') : tr(context, 'add_email_btn'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (hasEmail) ...[
                  const SizedBox(height: 6),
                  Text(
                    isVerified ? tr(context, 'verified_label') : tr(context, 'unverified_label'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? AppColors.success : Colors.red.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Phone Field ───────────────────────────────────────────────

  Widget _buildPhoneField(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    final phone = user.phoneNumber ?? '—';
    final hasPhone = phone != '—' && phone.trim().isNotEmpty;
    final isVerified = user.isPhoneVerified;
    final hasEmail = user.email.trim().isNotEmpty;
    // Locked if verified OR if it's a phone-based login (no email)
    final isLocked = isVerified || !hasEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'phone_number_label'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_outlined,
                  size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasPhone
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (hasPhone && isVerified)
                _buildVerifiedBadge(context, theme)
              else if (!isLocked)
                GestureDetector(
                  onTap: () => _showVerifyPhoneDialog(context, user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.actionBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasPhone ? 'EDIT' : 'ADD',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            tr(context, 'verified'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Display Fields (Read-only) ────────────────────────────────

  Widget _buildInfoField(
    BuildContext context,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: value == '—'
                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoFieldWithIcon(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == '—'
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoFieldWithWidgetIcon(
    BuildContext context,
    String label,
    String value,
    Widget iconWidget,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.actionBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == '—'
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr(context, 'logout'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr(context, 'cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthController>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(tr(context, 'logout')),
          ),
        ],
      ),
    );
  }

  // ─── OTP Verification Dialogs ──────────────────────────────────

  void _showVerifyEmailDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OtpVerificationDialog(
        type: 'email',
        currentValue: user.email,
        userId: user.id,
        onVerified: (String verifiedValue) async {
          // The verifyOtp call inside the dialog already updated the profile and synced with backend.
          // No need for redundant (and potentially stale) updateProfile/refreshProfile calls here.
        },
      ),
    );
  }

  void _showVerifyPhoneDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OtpVerificationDialog(
        type: 'phone',
        currentValue: user.phoneNumber ?? '',
        userId: user.id,
        onVerified: (String verifiedValue) async {
          // The verifyOtp call inside the dialog already updated the profile and synced with backend.
          // No need for redundant (and potentially stale) updateProfile/refreshProfile calls here.
        },
      ),
    );
  }

  // ─── My Orders ─────────────────────────────────────────────────

  Widget _buildMyOrdersSection(BuildContext context, ThemeData theme) {
    return Consumer<OrderController>(
      builder: (context, controller, child) {
        if (controller.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.fetchMyOrders(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.isLoading && controller.orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppColors.actionBlue),
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.actionBlue.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.actionBlue.withOpacity(0.2)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(context, 'no_orders_yet'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order history will appear here',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => controller.fetchMyOrders(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.actionBlue,
                          side: const BorderSide(color: AppColors.actionBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Start Shopping'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tip: Pull down to refresh your order list',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: controller.orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            return _buildOrderCard(context, order, theme);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ORDER #',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(order.createdAt.toIso8601String()),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          
          Container(
            height: 1,
            color: theme.dividerColor.withOpacity(0.08),
          ),
          
          // Order Items
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
            ),
            itemBuilder: (context, index) => _buildOrderItem(context, order.items[index], order.status, theme),
          ),
          
          Container(
            height: 1,
            color: theme.dividerColor.withOpacity(0.08),
          ),
          
          // Order Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AED ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(
                          orderId: order.id,
                          initialOrder: order,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.actionBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── My Reviews Section ──────────────────────────────────────────
  Widget _buildMyReviewsSection(BuildContext context, ThemeData theme) {
    return Consumer<OrderController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.userReviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppColors.actionBlue),
            ),
          );
        }

        if (controller.userReviews.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 48, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No Reviews Yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reviews will appear here after you rate products from your orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY REVIEWS (${controller.userReviews.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ...controller.userReviews.map((review) => _buildReviewCard(context, review, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${review.createdAt.day} ${months[review.createdAt.month - 1]} ${review.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName ?? 'Product',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showReviewEditDialog(context, review),
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.actionBlue),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: i < review.rating ? const Color(0xFFFFB800) : Colors.grey[300],
              );
            }),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.images[i],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60, height: 60, color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewEditDialog(BuildContext context, ReviewModel review) {
    int selectedRating = review.rating;
    final commentController = TextEditingController(text: review.comment);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'EDIT YOUR REVIEW',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedRating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              starIndex <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: starIndex <= selectedRating
                                  ? const Color(0xFFFFB800)
                                  : Colors.grey[350],
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setDialogState(() => isSubmitting = true);
                                final controller = context.read<OrderController>();
                                final success = await controller.editReview(
                                  reviewId: review.id,
                                  rating: selectedRating,
                                  comment: commentController.text.trim(),
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  if (success) {
                                    final auth = context.read<AuthController>();
                                    if (auth.currentUser != null && auth.currentUser!.id != null) {
                                      controller.fetchUserReviews(auth.currentUser!.id!);
                                    }
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Review updated!' : 'Failed to update review'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Update Review', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItem item, String orderStatus, ThemeData theme) {
    final bool isDelivered = orderStatus.toUpperCase() == 'DELIVERED';
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image with stack for quantity
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.product.thumbnail,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76, height: 76, color: Colors.grey[100],
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trText(context, item.product.name),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'AED ${item.priceAtOrder.toStringAsFixed(2)} / unit',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending': 
        color = Colors.orange; 
        icon = Icons.access_time_rounded;
        break;
      case 'delivered': 
        color = Colors.green; 
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled': 
        color = Colors.red; 
        icon = Icons.cancel_rounded;
        break;
      case 'shipped': 
        color = Colors.blue; 
        icon = Icons.local_shipping_rounded;
        break;
      default: 
        color = Colors.grey;
        icon = Icons.info_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color, 
              fontSize: 10, 
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, ProductModel product) {
    int rating = 5;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How was it?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          Text(
                            'Rate your experience with this product',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Product Info Mini
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(product.thumbnail, width: 40, height: 40, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          trText(context, product.name),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Rating Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isSelected = index < rating;
                    return GestureDetector(
                      onTap: () => setState(() => rating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? Colors.amber : Colors.grey.shade300,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 24),
                
                // Comment Field
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tell others what you thought about this product...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Consumer<OrderController>(
                        builder: (context, orderCtrl, _) => ElevatedButton(
                          onPressed: orderCtrl.isLoading ? null : () async {
                            final success = await orderCtrl.addReview(
                              productId: product.id,
                              rating: rating,
                              comment: controller.text.trim(),
                            );
                            if (mounted && success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for your review!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(orderCtrl.error ?? 'Failed to add review'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.actionBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: orderCtrl.isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('SUBMIT REVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Addresses ─────────────────────────────────────────────────

  Widget _buildAddressesSection(
    BuildContext context,
    ThemeData theme,
  ) {
    const isDark = false;
    return Consumer<AddressController>(
      builder: (context, addressCtrl, _) {
        final addresses = addressCtrl.addresses;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Address Button at the top
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => const AddAddressDialog(),
                  );
                },
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                label: Text(
                   tr(context, 'add_new_address').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.actionBlue.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              
              if (addresses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'no_addresses_saved'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final a in addresses)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.actionBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (a.type ?? 'other').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.actionBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (a.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  if (a.id != null) {
                                    addressCtrl.deleteAddress(a.id!);
                                  }
                                },
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (a.firstName != null || a.lastName != null) ...[
                             Text(
                                '${a.firstName ?? ''} ${a.lastName ?? ''}'.trim(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             ),
                             const SizedBox(height: 6),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a.line1}${a.line2 != null && a.line2!.isNotEmpty ? ', ${a.line2}' : ''}',
                                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${a.city}, ${a.state}${a.postalCode != null && a.postalCode!.isNotEmpty ? ' - ${a.postalCode}' : ''}',
                                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (a.phoneNumber != null && a.phoneNumber!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                const SizedBox(width: 8),
                                Text(
                                  a.phoneNumber!,
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                          if (a.landmark != null && a.landmark!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    a.landmark!,
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  String _getGenderLabel(String? code) {
    if (code == null || code.trim().isEmpty) return '—';
    switch (code.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        // Handle case where server might already have full strings
        if (code.toLowerCase() == 'male') return 'Male';
        if (code.toLowerCase() == 'female') return 'Female';
        if (code.toLowerCase() == 'other') return 'Other';
        return code;
    }
  }
}


// ─── Guest View ─────────────────────────────────────────────────


/// Guest view: OTP login card and link to registration.
class _NotLoggedInView extends StatelessWidget {
  final ThemeData theme;

  const _NotLoggedInView({required this.theme});

  @override
  Widget build(BuildContext context) {
    const isDark = false;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.bgGradient,
              )
            : null,
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'welcome_back'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(context, 'otp_sign_in'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const UnifiedAuthForm(),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr(context, 'join_network_prompt'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/register'),
                      child: Text(
                        tr(context, 'join_network'),
                        style: const TextStyle(
                          color: AppColors.actionBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
