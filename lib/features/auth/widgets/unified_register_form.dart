import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class UnifiedRegisterForm extends StatefulWidget {
  const UnifiedRegisterForm({super.key});

  @override
  State<UnifiedRegisterForm> createState() => _UnifiedRegisterFormState();
}

class _UnifiedRegisterFormState extends State<UnifiedRegisterForm> {
  bool _isPhoneMode = true;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _agreedToTerms = false;
  String _selectedCountryCode = '+971';
  bool _showErrors = false;
  bool _viaWhatsApp = false;

  final List<Map<String, dynamic>> _countries = [
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪', 'hint': 'phone_hint_uae', 'maxLength': 9, 'pattern': r'^(50|52|54|55|56|58)\d{7}$', 'key': 'uae'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  bool get _isValidInput {
    final text = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();
    if (text.isEmpty) return false;
    if (_firstNameController.text.trim().isEmpty) return false;
    if (_lastNameController.text.trim().isEmpty) return false;
    if (!_agreedToTerms) return false;

    if (_isPhoneMode) {
      final country = _countries.firstWhere((c) => c['code'] as String == _selectedCountryCode);
      final pattern = country['pattern'] as String;
      return RegExp(pattern).hasMatch(text);
    }
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  String _generateSecurePassword() {
    // Generate a strong random password to satisfy API requirements
    final random = Random.secure();
    final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showErrors = true;
    });

    if (!_isValidInput) return;

    final authController = context.read<AuthController>();
    String text = _phoneController.text.trim();
    if (_isPhoneMode && text.startsWith('0')) {
      text = text.substring(1);
    }
    
    // Ensure identifier has + prefix for consistency
    final identifier = _isPhoneMode 
        ? (_selectedCountryCode.startsWith('+') ? '$_selectedCountryCode$text' : '+$_selectedCountryCode$text')
        : _emailController.text.trim();
    
    final currentPassword = _generateSecurePassword();
    
    // 1. Attempt registration
    final registerSuccess = await authController.register(
      email: _isPhoneMode ? '' : identifier, 
      phoneNumber: _isPhoneMode ? identifier : '', 
      password: currentPassword,
      passwordConfirm: currentPassword,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      referralCode: _referralController.text.trim(),
    );

    // 2. If registration fails because user already exists, that's fine - we'll just try to login via OTP
    bool shouldProceedToOtp = registerSuccess;
    if (!registerSuccess) {
      final err = authController.errorMessage?.toLowerCase() ?? '';
      if (err.contains('already exists') || err.contains('taken')) {
        debugPrint('User already exists, proceeding to OTP request for login');
        shouldProceedToOtp = true;
        authController.clearError();
      }
    }

    // 3. Request OTP for login
    if (shouldProceedToOtp && mounted) {
      final otpSuccess = await authController.requestOtp(identifier: identifier, viaWhatsApp: _isPhoneMode ? _viaWhatsApp : false);
      if (otpSuccess && mounted) {
         Navigator.of(context).pushNamed('/otp', arguments: identifier);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ─── Tabs ────────────────────────────────────────────────
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkGrey : const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTab(context, 'phone', _isPhoneMode, () {
                final hasFocus = _emailFocusNode.hasFocus;
                if (hasFocus) FocusScope.of(context).unfocus();
                setState(() { _isPhoneMode = true; _showErrors = false; });
                if (hasFocus) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _phoneFocusNode.requestFocus();
                  });
                } else {
                  FocusScope.of(context).unfocus();
                }
              })),
              Expanded(child: _buildTab(context, 'email', !_isPhoneMode, () {
                final hasFocus = _phoneFocusNode.hasFocus;
                if (hasFocus) FocusScope.of(context).unfocus();
                setState(() { _isPhoneMode = false; _showErrors = false; });
                if (hasFocus) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _emailFocusNode.requestFocus();
                  });
                } else {
                  FocusScope.of(context).unfocus();
                }
              })),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── Names ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _buildInputField(theme, _firstNameController, 'register_first_name_label', 'first_name_hint')),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField(theme, _lastNameController, 'register_last_name_label', 'last_name_hint')),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Referral Code ──────────────────────────────────────────
        _buildInputField(theme, _referralController, 'referral_code_label', 'referral_code_hint', isReferral: true),
        const SizedBox(height: 24),

        // ─── Contact Field ─────────────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            tr(context, _isPhoneMode ? 'phone' : 'email'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (_isPhoneMode) ...[
          _buildPhoneField(theme),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _viaWhatsApp,
                  onChanged: (val) {
                    setState(() {
                      _viaWhatsApp = val ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Send OTP via WhatsApp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildEmailField(theme),
        ],

        // ─── Validation & Server Error Message ─────────────────────────────
        _buildErrorDisplay(context, theme),

        const SizedBox(height: 16),

        // ─── Terms Checkbox ───────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      letterSpacing: 0.5,
                      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      TextSpan(text: tr(context, 'agree_prefix')),
                      TextSpan(
                        text: tr(context, 'TERMS'),
                        style: const TextStyle(
                          color: AppColors.actionBlue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchURL(
                              'https://simakfresh.ae/terms-of-service'),
                      ),
                      TextSpan(text: tr(context, 'and')),
                      TextSpan(
                        text: tr(context, 'PRIVACY'),
                        style: const TextStyle(
                          color: AppColors.actionBlue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              _launchURL('https://simakfresh.ae/privacy-policy'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Send OTP Button ──────────────────────────────────────
        Consumer<AuthController>(
          builder: (context, auth, _) {
            final namesFilled = _firstNameController.text.trim().isNotEmpty && _lastNameController.text.trim().isNotEmpty;
            final isActive = namesFilled && _isValidInput && _agreedToTerms && !auth.isLoading;
            return SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive ? _handleRegister : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppColors.actionBlue : AppColors.actionBlue.withOpacity(0.2),
                  disabledBackgroundColor: AppColors.actionBlue.withOpacity(0.2),
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: auth.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr(context, 'send_otp'),
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // ─── Auth Options Divider ─────────────────────────────────
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, 'auth_options'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Google Sign In (Website Style) ───────────────────────
        Consumer<AuthController>(
          builder: (context, auth, _) {
            return SizedBox(
              height: 54,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: auth.isLoading ? null : () async {
                  final success = await auth.signInWithGoogle();
                  if (success && context.mounted) {
                    auth.handleAuthNavigation(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: auth.isLoading && auth.errorMessage == null 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImage(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tr(context, 'google_sign_in'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String titleKey, bool isActive, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                titleKey == 'phone' ? Icons.phone_outlined : Icons.email_outlined,
                size: 16,
                color: isActive ? AppColors.actionBlue : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, titleKey),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme, TextEditingController controller, String labelKey, String hintKey, {bool isReferral = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, labelKey),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: Icon(
                isReferral ? Icons.card_giftcard_outlined : Icons.person_outline, 
                size: 20, 
                color: theme.colorScheme.onSurface.withOpacity(0.3)
              ),
              hintText: tr(context, hintKey),
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    final currentCountry = _countries.firstWhere((c) => c['code'] == _selectedCountryCode);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.phone_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ),
          // Country Selector
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.actionBlue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currentCountry['flag'] as String, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(currentCountry['code'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Phone Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: currentCountry['maxLength'] as int,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: tr(context, currentCountry['hint'] as String),
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.email_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ),
          Expanded(
            child: TextField(
               controller: _emailController,
               focusNode: _emailFocusNode,
               keyboardType: TextInputType.emailAddress,
               onChanged: (_) => setState(() {}),
               decoration: InputDecoration(
                hintText: tr(context, 'enter_email_hint'),
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(BuildContext context, ThemeData theme) {
    // 1. Check for Server Error first
    final auth = context.read<AuthController>();
    if (auth.errorMessage != null && _showErrors) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
          auth.errorMessage!,
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 2. Fallback to Local Validation Error
    if (!_showErrors) return const SizedBox.shrink();
    final text = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();
    if (text.isEmpty || _isValidInput) return const SizedBox.shrink();

    String? errorMessage;
    if (_isPhoneMode) {
      final country = _countries.firstWhere((c) => c['code'] as String == _selectedCountryCode);
      final maxLength = country['maxLength'] as int;
      if (text.length != maxLength) {
        errorMessage = tr(context, 'valid_phone_for_country');
      }
    } else {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
        errorMessage = tr(context, 'enter_valid_email');
      }
    }

    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
