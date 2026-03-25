import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class CountryCode {
  final String name;
  final String code;
  final String flag;
  final String hint;
  final int maxLength;
  final String pattern;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.hint,
    required this.maxLength,
    required this.pattern,
  });
}

const List<CountryCode> supportedCountries = [
  CountryCode(name: 'UAE', code: '+971', flag: '🇦🇪', hint: '9 digits', maxLength: 9, pattern: r'^(50|52|54|55|56|58)\d{7}$'),
  CountryCode(name: 'India', code: '+91', flag: '🇮🇳', hint: '10 digits', maxLength: 10, pattern: r'^[6-9]\d{9}$'),
  CountryCode(name: 'China', code: '+86', flag: '🇨🇳', hint: '11 digits', maxLength: 11, pattern: r'^(13|14|15|16|17|18|19)\d{9}$'),
];

class OtpVerificationDialog extends StatefulWidget {
  final String type; // 'email' or 'phone'
  final String currentValue;
  final int? userId;
  final Function(String)? onVerified; // Callback for when verification is successful

  const OtpVerificationDialog({
    super.key,
    required this.type,
    required this.currentValue,
    this.userId,
    this.onVerified,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  late CountryCode _selectedCountry;

  Timer? _timer;
  int _secondsRemaining = 120; 
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = supportedCountries[0];

    if (widget.currentValue.isNotEmpty) {
      if (!_isEmail) {
        String initialValue = widget.currentValue;
        if (!initialValue.startsWith('+')) {
          _inputController.text = initialValue;
        } else {
          bool found = false;
          for (var country in supportedCountries) {
            if (initialValue.startsWith(country.code)) {
              _selectedCountry = country;
              _inputController.text = initialValue.substring(country.code.length);
              found = true;
              break;
            }
          }
          if (!found) {
            _inputController.text = initialValue;
          }
        }
      } else {
        _inputController.text = widget.currentValue;
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _isEmail => widget.type == 'email';

  String get _title => _isEmail ? tr(context, 'otp_verify_email_title') : tr(context, 'otp_verify_phone_title');
  String get _subtitle => _isEmail
      ? tr(context, 'otp_verify_email_subtitle')
      : tr(context, 'otp_verify_phone_subtitle');
  String get _inputLabel => _isEmail ? tr(context, 'email_address_label') : tr(context, 'phone_number_label');
  String get _inputHint => _isEmail ? tr(context, 'enter_email_hint') : _selectedCountry.hint;

  String get _fullIdentifier {
    final val = _inputController.text.trim();
    if (_isEmail) return val;
    String local = val;
    if (local.startsWith('0')) {
      local = local.substring(1);
    }
    return '${_selectedCountry.code}$local';
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _timerDisplay {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_isInputValid) {
      return;
    }
 
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final success = await auth.requestOtp(identifier: _fullIdentifier);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
        _startTimer();
      } else {
        _errorMessage = auth.errorMessage ?? tr(context, 'failed_to_send_otp');
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final identifier = _fullIdentifier;
    final success = await auth.verifyOtp(identifier: identifier, otp: otp);

    if (!mounted) return;

    if (success) {
      if (widget.onVerified != null) {
        await widget.onVerified!(identifier);
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        // The verifyOtp call already updated the profile and synced with backend.
        // Direct pop is safe.
        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEmail
                ? tr(context, 'otp_verify_email_success')
                : tr(context, 'otp_verify_phone_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ?? tr(context, 'otp_verify_failed');
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get _isInputValid {
    final text = _inputController.text.trim();
    if (text.isEmpty) return false;
    if (_isEmail) return _isValidEmail(text);
    return RegExp(_selectedCountry.pattern).hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],



              if (!_otpSent) ...[
                Text(
                  _inputLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEmail)
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (_) => setState(() => _errorMessage = null),
                    decoration: _inputDecoration(isDark),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CountryCode>(
                            value: _selectedCountry,
                            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            selectedItemBuilder: (context) {
                              return supportedCountries.map((c) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.flag, style: const TextStyle(fontSize: 18)),
                                  ],
                                );
                              }).toList();
                            },
                            items: supportedCountries.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 140),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c.flag,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.code,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCountry = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          keyboardType: TextInputType.phone,
                          maxLength: _selectedCountry.maxLength,
                          inputFormatters: _isEmail ? null : [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration(isDark).copyWith(
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isInputValid) ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4DB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF00B4DB).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            tr(context, 'send_otp'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              if (_otpSent) ...[
                Text(
                  '${tr(context, 'otp_sent_to')} $_fullIdentifier',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'enter_otp_label'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDecoration(isDark).copyWith(
                    hintText: tr(context, 'enter_otp_hint'),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _secondsRemaining <= 30
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.actionBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _secondsRemaining <= 30
                                ? Colors.red
                                : AppColors.actionBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timerDisplay,
                            style: TextStyle(
                              fontSize: 13,
                              color: _secondsRemaining <= 30
                                  ? Colors.red
                                  : AppColors.actionBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_canResend)
                      GestureDetector(
                        onTap: _sendOtp,
                        child: Text(
                          tr(context, 'resend_otp'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.actionBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4DB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                        _errorMessage = null;
                        _timer?.cancel();
                      });
                    },
                    child: Text(
                      'Change ${_isEmail ? 'Email' : 'Phone Number'}',
                      style: const TextStyle(
                        color: AppColors.actionBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      hintText: _inputHint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.actionBlue, width: 1.5),
      ),
    );
  }

}

