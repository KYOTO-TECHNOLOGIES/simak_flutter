import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final success = await authController.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Name Row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: _inputDecoration(
                    theme: theme,
                    label: tr(context, 'first_name'),
                    hint: tr(context, 'first_name_hint'),
                    icon: Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? tr(context, 'required') : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: _inputDecoration(
                    theme: theme,
                    label: tr(context, 'last_name'),
                    hint: tr(context, 'last_name_hint'),
                    icon: Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? tr(context, 'required') : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Email ────────────────────────────────────────
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: _inputDecoration(
              theme: theme,
              label: tr(context, 'email_label'),
              hint: tr(context, 'email_hint'),
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr(context, 'email_required');
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return tr(context, 'valid_email');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ─── Phone ────────────────────────────────────────
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: _inputDecoration(
              theme: theme,
              label: tr(context, 'phone_number'),
              hint: tr(context, 'phone_hint_reg'),
              icon: Icons.phone_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr(context, 'phone_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ─── Password ─────────────────────────────────────
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: _inputDecoration(
              theme: theme,
              label: tr(context, 'password_label'),
              hint: tr(context, 'password_hint'),
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return tr(context, 'password_required');
              if (value.length < 6) return tr(context, 'min_6_chars');
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ─── Confirm Password ─────────────────────────────
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: _obscureConfirm,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: _inputDecoration(
              theme: theme,
              label: tr(context, 'confirm_password'),
              hint: tr(context, 'reenter_password'),
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr(context, 'confirm_password_req');
              }
              if (value != _passwordController.text) {
                return tr(context, 'passwords_no_match');
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ─── Submit Button ────────────────────────────────
          Consumer<AuthController>(
            builder: (context, auth, _) {
              return SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          tr(context, 'create_account_btn'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ThemeData theme,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
