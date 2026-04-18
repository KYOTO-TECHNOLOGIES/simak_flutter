import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 120; // 2 minutes = 120 seconds
  String? _identifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _identifier = ModalRoute.of(context)?.settings.arguments as String?;
      _startTimer();
    });
  }

  void _startTimer({bool isResend = false}) {
    setState(() => _secondsRemaining = isResend ? 40 : 120);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isOtpComplete {
    return _otpControllers.every((c) => c.text.isNotEmpty);
  }

  String _formatIdentifier(String identifier) {
    if (identifier.isEmpty) return identifier;

    // Check if it's an email
    if (identifier.contains('@')) {
      // Format email: show first 3 chars, some stars, and domain
      final parts = identifier.split('@');
      if (parts.length != 2) return identifier;

      final localPart = parts[0];
      final domain = parts[1];

      if (localPart.length <= 3) {
        return '$localPart***@$domain';
      } else {
        return '${localPart.substring(0, 3)}***@$domain';
      }
    } else {
      // Format phone number: show country code and last 4 digits
      if (identifier.length <= 6) {
        return identifier;
      }

      // Extract country code (assuming it starts with +)
      String countryCode = '';
      String number = identifier;

      if (identifier.startsWith('+')) {
        // Find where the country code ends (first space or after 3-4 digits)
        int countryCodeEnd = 1;
        while (countryCodeEnd < identifier.length &&
            countryCodeEnd < 5 &&
            identifier[countryCodeEnd] != ' ') {
          countryCodeEnd++;
        }

        if (countryCodeEnd < identifier.length &&
            identifier[countryCodeEnd] == ' ') {
          countryCode = identifier.substring(0, countryCodeEnd + 1);
          number = identifier.substring(countryCodeEnd + 1);
        } else {
          countryCode = identifier.substring(0, countryCodeEnd);
          number = identifier.substring(countryCodeEnd);
        }
      }

      if (number.length <= 4) {
        return identifier;
      }

      final lastFour = number.substring(number.length - 4);
      final maskedNumber = '*' * (number.length - 4);

      return '$countryCode$maskedNumber$lastFour';
    }
  }

  Future<void> _resendOtp() async {
    if (_identifier == null) return;
    final auth = context.read<AuthController>();
    final success = await auth.requestOtp(identifier: _identifier!);
    if (success && mounted) {
      _startTimer(isResend: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'otp_sent_msg')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _identifier == null) return;

    final otp = _otpControllers.map((c) => c.text).join();
    final auth = context.read<AuthController>();
    final success = await auth.verifyOtp(identifier: _identifier!, otp: otp);

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context.read<AuthController>().resetOtpState();
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // UI Card Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : AppColors.white,
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
                        children: [
                          // Graphic Icon
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              size: 32,
                              color: AppColors.actionBlue,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Titles
                          Text(
                            tr(context, 'enter_otp'),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We have sent a verification code to\n${_formatIdentifier(_identifier ?? "")}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // OTP Input Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 42,
                                height: 52,
                                child: TextFormField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: theme.scaffoldBackgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.actionBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                    setState(() {}); // Update button state
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),

                          // Error message if any
                          Consumer<AuthController>(
                            builder: (context, auth, _) {
                              if (auth.errorMessage == null)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),

                          // Verify Button
                          Consumer<AuthController>(
                            builder: (context, auth, _) {
                              return SizedBox(
                                height: 54,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (_isOtpComplete && !auth.isLoading)
                                      ? _verifyOtp
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.actionBlue,
                                    disabledBackgroundColor: AppColors
                                        .actionBlue
                                        .withOpacity(0.3),
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          tr(context, 'verify_login'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Timer / Resend Row
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive the code? ",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _secondsRemaining > 0
                                        ? null
                                        : _resendOtp,
                                    child: Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                        color: _secondsRemaining > 0
                                            ? theme.colorScheme.onSurface
                                                  .withOpacity(0.3)
                                            : AppColors.actionBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_secondsRemaining > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _secondsRemaining <= 30
                                          ? Colors.red.withOpacity(0.1)
                                          : AppColors.actionBlue.withOpacity(
                                              0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 18,
                                          color: _secondsRemaining <= 30
                                              ? Colors.red
                                              : AppColors.actionBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formattedTime,
                                          style: TextStyle(
                                            color: _secondsRemaining <= 30
                                                ? Colors.red
                                                : AppColors.actionBlue,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
