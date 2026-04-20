class DeliveryOfferModel {
  final int id;
  final Map<String, dynamic> promotionalTexts;

  DeliveryOfferModel({
    required this.id,
    required this.promotionalTexts,
  });

  factory DeliveryOfferModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOfferModel(
      id: json['id'] ?? 0,
      promotionalTexts: json['promotional_texts'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['promotional_texts'])
          : {},
    );
  }

  String getFreeDelivery(String langCode) {
    // Map 'cn' (app) to 'zh' (API)
    final code = langCode == 'cn' ? 'zh' : langCode;
    
    // Safely retrieve the language map
    final langData = promotionalTexts[code];
    if (langData is Map<String, dynamic>) {
      final text = langData['free_delivery'];
      if (text != null) return text.toString();
    }

    // Fallback to English
    final enData = promotionalTexts['en'];
    if (enData is Map<String, dynamic>) {
      final text = enData['free_delivery'];
      if (text != null) return text.toString();
    }

    return '';
  }

  String getDeliveryTime(String langCode) {
    // Map 'cn' (app) to 'zh' (API)
    final code = langCode == 'cn' ? 'zh' : langCode;
    
    // Safely retrieve the language map
    final langData = promotionalTexts[code];
    if (langData is Map<String, dynamic>) {
      final text = langData['delivery_time'];
      if (text != null) return text.toString();
    }

    // Fallback to English
    final enData = promotionalTexts['en'];
    if (enData is Map<String, dynamic>) {
      final text = enData['delivery_time'];
      if (text != null) return text.toString();
    }

    return '';
  }
}
