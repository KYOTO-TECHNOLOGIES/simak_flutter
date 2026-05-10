import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/delivery/model/delivery_model.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final deliveryController = context.watch<DeliveryController>();
    final data = deliveryController.dashboardData;
    final profile = data?.profile;
    final emirates =
        profile?.assignedEmiratesDisplay.join(', ') ?? 'NONE ASSIGNED';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3436),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            // ─── Profile Summary Card ──────────────────────────────
            _buildProfileSummaryCard(user, profile),

            const SizedBox(height: 16),

            // ─── Achievement Stats ───────────────────────────────
            _buildAchievementStats(data),

            const SizedBox(height: 32),

            // ─── Account & Contact Section ───────────────────────
            _buildInfoSection(
              title: 'ACCOUNT & CONTACT',
              items: [
                _InfoItem(
                  icon: Icons.email_outlined,
                  label: 'EMAIL ADDRESS',
                  value: user?.email ?? 'Not available',
                ),
                _InfoItem(
                  icon: Icons.phone_outlined,
                  label: 'PHONE NUMBER',
                  value: user?.phoneNumber ?? 'Not Provided',
                  onTap: () => _showEditPhoneDialog(context),
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'ASSIGNED EMIRATE',
                  value: '',
                )..dynamicValue = emirates,
              ],
            ),

            const SizedBox(height: 24),

            // ─── Personal & Preferences Section ───────────────────
            _buildInfoSection(
              title: 'PERSONAL & PREFERENCES',
              items: [
                _InfoItem(
                  icon: Icons.person_outline,
                  label: 'FIRST NAME',
                  value: user?.firstName ?? 'N/A',
                ),
                _InfoItem(
                  icon: Icons.person_outline,
                  label: 'LAST NAME',
                  value: user?.lastName ?? 'N/A',
                ),
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'DATE OF BIRTH',
                  value: user?.profile?.dateOfBirth ?? 'Not set',
                  onTap: () => _selectDateOfBirth(context),
                ),
                _InfoItem(
                  icon: Icons.history_outlined,
                  label: 'JOINED SIMAK',
                  value: user?.createdAt != null
                      ? user!
                            .createdAt! // It's a string, so just use it or parse
                      : 'N/A',
                ),
              ],
            ),

            const SizedBox(height: 48),

            // ─── Sign Out Button ─────────────────────────────────
            _buildSignOutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(dynamic user, DeliveryProfile? profile) {
    final isAvailable = profile?.isAvailable ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Online Status Badge
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFE3F9E5)
                    : const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF43D152) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? 'AVAILABLE' : 'OFFLINE',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? const Color(0xFF43D152) : Colors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // Avatar with Edit Button
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007AFF), AppColors.actionBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.actionBlue.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.actionBlue,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F2F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: AppColors.actionBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                '${user?.firstName ?? "Abu"} ${user?.lastName ?? "Rider"}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 8),
              // Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.actionBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'DELIVERY BOY',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.actionBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Partner ID: #${profile?.id ?? "N/A"}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStats(DeliveryDashboardData? data) {
    return Row(
      children: [
        _StatCard(
          label: 'RATING',
          value: '${data?.profile.rating ?? 0.0}',
          icon: Icons.star_rounded,
          color: Color(0xFFFFA800),
          bgColor: Color(0xFFFFF9EB),
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'TOTAL ORDERS',
          value: '${data?.completedTotal ?? 0}',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.actionBlue,
          bgColor: Color(0xFFF1FBFF),
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'EARNINGS',
          value: 'AED ${(data?.profile.earningsTotal ?? 0).toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF43D152),
          bgColor: Color(0xFFEBFAED),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.6),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F2F6)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: items.map((item) {
              final isLast = items.indexOf(item) == items.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.dynamicValue ?? item.value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3436),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.onTap != null)
                            Icon(
                              Icons.edit_note_outlined,
                              size: 20,
                              color: AppColors.actionBlue.withOpacity(0.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: Color(0xFFF1F2F6)),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showEditPhoneDialog(BuildContext context) {
    final authController = context.read<AuthController>();
    final phoneController = TextEditingController(
      text: authController.currentUser?.phoneNumber,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Update Phone Number',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+971XXXXXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await authController.updateProfile({
                'phone_number': phoneController.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Phone number updated' : 'Update failed',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SAVE',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final authController = context.read<AuthController>();
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );

    if (authController.currentUser?.profile?.dateOfBirth != null) {
      try {
        initialDate = DateTime.parse(
          authController.currentUser!.profile!.dateOfBirth!,
        );
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.actionBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      final success = await authController.updateProfile({
        'profile': {'date_of_birth': formattedDate},
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Date of birth updated' : 'Update failed'),
          ),
        );
      }
    }
  }

  Widget _buildSignOutButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.read<AuthController>().logout();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false, arguments: 2);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout, color: Color(0xFFFF4D4D), size: 18),
          const SizedBox(width: 8),
          Text(
            'Sign Out of Portal',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF4D4D),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  String? dynamicValue;
  final VoidCallback? onTap;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
}
