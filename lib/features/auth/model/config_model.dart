class ConfigModel {
  final String? googleMapsApiKey;
  final String? appName;
  final String? contactEmail;
  final String? contactPhone;

  ConfigModel({
    this.googleMapsApiKey,
    this.appName,
    this.contactEmail,
    this.contactPhone,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      googleMapsApiKey: json['google_maps_api_key'] as String?,
      appName: json['app_name'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'google_maps_api_key': googleMapsApiKey,
      'app_name': appName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
    };
  }
}
