import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class UnifiedAuthForm extends StatefulWidget {
  const UnifiedAuthForm({super.key});

  @override
  State<UnifiedAuthForm> createState() => _UnifiedAuthFormState();
}

class _UnifiedAuthFormState extends State<UnifiedAuthForm> {
  bool _isPhoneMode = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  
  bool _agreedToTerms = false;
  String _selectedCountryCode = '+971';
  bool _showPhoneError = false;
  bool _showEmailError = false;

  final List<Map<String, dynamic>> _countries = [
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪', 'hint': 'phone_hint_uae', 'maxLength': 9, 'pattern': r'^(50|52|54|55|56|58)\d{7}$', 'key': 'uae'},
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳', 'hint': 'phone_hint_india', 'maxLength': 10, 'pattern': r'^[6-9]\d{9}$', 'key': 'india'},
    {'name': 'China', 'code': '+86', 'flag': '🇨🇳', 'hint': 'phone_hint_china', 'maxLength': 11, 'pattern': r'^(13|14|15|16|17|18|19)\d{9}$', 'key': 'china'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onPhoneFocusChange);
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  void _onPhoneFocusChange() {
    if (!_phoneFocusNode.hasFocus && _phoneController.text.isNotEmpty) {
      if (!_isIdentifierValid(_phoneController.text.trim(), true)) {
        setState(() => _showPhoneError = true);
      }
    }
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
      if (!_isIdentifierValid(_emailController.text.trim(), false)) {
        setState(() => _showEmailError = true);
      }
    }
  }

  bool _isIdentifierValid(String text, bool isPhone) {
    if (text.isEmpty) return false;
    if (isPhone) {
      final country = _countries.firstWhere((c) => c['code'] as String == _selectedCountryCode);
      final pattern = country['pattern'] as String;
      return RegExp(pattern).hasMatch(text);
    }
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _phoneFocusNode.removeListener(_onPhoneFocusChange);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  bool get _isValidInput {
    final text = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();
    return _isIdentifierValid(text, _isPhoneMode);
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();

    String text = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();
    final bool isInputValid = _isIdentifierValid(text, _isPhoneMode);
    
    if (!isInputValid) {
      setState(() {
        if (_isPhoneMode) _showPhoneError = true;
        else _showEmailError = true;
      });
      return;
    }

    final authController = context.read<AuthController>();
    if (_isPhoneMode && text.startsWith('0')) {
      text = text.substring(1);
    }

    final identifier = _isPhoneMode 
        ? (_selectedCountryCode.startsWith('+') ? '$_selectedCountryCode$text' : '+$_selectedCountryCode$text')
        : text;

    final success = await authController.requestOtp(identifier: identifier);
    
    if (success && mounted) {
      // Navigate to OTP verification screen passing the identifier
      Navigator.of(context).pushNamed('/otp', arguments: identifier);
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
              Expanded(child: _buildTab(context, 'phone', _isPhoneMode, () => setState(() { _isPhoneMode = true; }))),
              Expanded(child: _buildTab(context, 'email', !_isPhoneMode, () => setState(() { _isPhoneMode = false; }))),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── Input Field ──────────────────────────────────────────
        if (_isPhoneMode)
          _buildPhoneField(theme)
        else
          _buildEmailField(theme),

        // ─── Validation & Server Error Message ─────────────────────────────
        _buildErrorDisplay(context, theme),



        const SizedBox(height: 16),

        // ─── Terms Checkbox ───────────────────────────────────────
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
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
            final isActive = _isValidInput && _agreedToTerms && !auth.isLoading;
            return SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isActive ? _handleSendOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppColors.actionBlue : AppColors.actionBlue.withOpacity(0.2),
                  disabledBackgroundColor: AppColors.actionBlue.withOpacity(0.2),
                  foregroundColor: AppColors.white,
                  elevation: isActive ? 2 : 0,
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
        /* Row(
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
                  if (success && mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
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
        ), */
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
            child: PopupMenuButton<Map<String, dynamic>>(
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.cardColor,
              elevation: 8,
              onSelected: (country) {
                setState(() {
                  _selectedCountryCode = country['code']!;
                });
              },
              itemBuilder: (context) => _countries.map((c) => PopupMenuItem(
                value: c,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 40,
                child: Row(
                  children: [
                    Text(c['flag'] as String, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trStatic(context, c['key'] as String), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.actionBlue, fontSize: 13)
                      ),
                    ),
                    Text(c['code'] as String, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              )).toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentCountry['flag'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
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
              onChanged: (value) {
                if (_showPhoneError) {
                  setState(() => _showPhoneError = false);
                } else {
                  setState(() {}); // Still need to update "Send OTP" button state
                }
              },
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
              onChanged: (value) {
                if (_showEmailError) {
                  setState(() => _showEmailError = false);
                } else {
                  setState(() {});
                }
              },
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
    if (auth.errorMessage != null) {
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

    // 2. Fallback to Local Validation Error (only show if intended)
    final bool shouldShowError = _isPhoneMode ? _showPhoneError : _showEmailError;
    if (!shouldShowError) return const SizedBox.shrink();

    final text = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    
    if (_isIdentifierValid(text, _isPhoneMode)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        tr(context, _isPhoneMode ? 'valid_phone_for_country' : 'enter_valid_email'),
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

