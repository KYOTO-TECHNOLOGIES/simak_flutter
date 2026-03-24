import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';

class LanguageSelectionIcon extends StatelessWidget {
  const LanguageSelectionIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = context.watch<LanguageProvider>();
    final currentLocale = languageProvider.locale;

    return GestureDetector(
      onTap: () => _showLanguagePicker(context),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _getLanguageDisplay(currentLocale),
        ),
      ),
    );
  }

  Widget _getLanguageDisplay(String code) {
    String label;
    switch (code) {
      case 'en': label = 'EN'; break;
      case 'ar': label = 'AR'; break;
      case 'cn': 
      case 'zh': label = 'CN'; break;
      default: label = code.toUpperCase();
    }
    
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const _LanguagePickerSheet();
      },
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(context, 'select_language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageItem(context, 'en', 'English', '🇺🇸'),
            _buildLanguageItem(context, 'ar', 'العربية (Arabic)', '🇦🇪'),
            _buildLanguageItem(context, 'cn', '中文 (Chinese)', '🇨🇳'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String code, String label, String flag) {
    final languageProvider = context.watch<LanguageProvider>();
    final isSelected = languageProvider.locale == code;
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            flag,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) 
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: () {
        languageProvider.setLocale(code);
        Navigator.pop(context);
      },
    );
  }
}
