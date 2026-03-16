import 'package:uae_ecom_project/features/products/model/product_model.dart';

class MarketingModel {
  final int id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? link;
  final String? type;
  final String? tag;
  final String? ctaText;

  MarketingModel({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.link,
    this.type,
    this.tag,
    this.ctaText,
  });

  factory MarketingModel.fromJson(Map<String, dynamic> json) {
    final rawImagePath = json['image_mobile'] ??
      json['image_desktop'] ??
      json['image'] ?? 
      json['media'] ?? 
      json['banner_image'] ?? 
      json['background_image'] ?? 
      json['file'] ??
      json['attachment'] ??
      json['banner_img'];

    final imageUrl = ProductModel.getAbsoluteUrl(rawImagePath);
    
    // ignore: avoid_print
    print('Marketing Banner Parsed URL: $imageUrl');

    // Helper to get non-empty string or null
    String? nonEmpty(dynamic value) {
      if (value == null) return null;
      final s = value.toString().trim();
      return s.isEmpty ? null : s;
    }

    return MarketingModel(
      id: json['id'] ?? 0,
      image: imageUrl,
      title: json['title'] ?? json['headline'] ?? json['name'] ?? json['banner_title'] ?? json['title_en'],
      subtitle: json['subtitle'] ?? json['description'] ?? json['content'] ?? json['banner_subtitle'] ?? json['description_en'],
      link: json['link'] ?? json['url'] ?? json['cta_link'] ?? json['redirect_url'] ?? json['button_link'],
      type: json['type'] ?? json['category'] ?? json['banner_type'] ?? json['tag_label'],
      tag: json['tag'] ?? json['label'] ?? json['badge'] ?? json['promotional_tag'] ?? json['offer_tag'],
      ctaText: nonEmpty(json['cta_text']) ?? 
               nonEmpty(json['button_text']) ?? 
               nonEmpty(json['cta_button']) ?? 
               nonEmpty(json['cta']) ?? 
               'Shop Now',
    );
  }
}
