/// Admin-entered translations resolved from canonical English API/cache data.
/// This keeps offline language changes immediate and category filters stable.
class CatalogLocalization {
  static String locale = 'en';

  static String normalize(String code) {
    final primary = code.toLowerCase().replaceAll('_', '-').split('-').first;
    if (primary == 'ar') return 'ar';
    if (primary == 'zh' || primary == 'cn') return 'cn';
    return 'en';
  }

  static String? optionalText(
    Map<String, dynamic> fields,
    String field,
    String? fallback,
  ) {
    final value = text(fields, field, fallback ?? '');
    return value.isEmpty ? fallback : value;
  }

  static String text(
    Map<String, dynamic> fields,
    String field,
    String fallback,
  ) {
    final suffix = switch (normalize(locale)) {
      'ar' => 'arabic',
      'cn' => 'chinese',
      _ => '',
    };
    final translated =
        suffix.isEmpty
            ? ''
            : fields['${field}_$suffix']?.toString().trim() ?? '';
    return translated.isNotEmpty ? translated : fallback;
  }
}
