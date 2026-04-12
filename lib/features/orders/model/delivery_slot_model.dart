class DeliverySlotModel {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String cutoffTime;
  final String startTimeDisplay;
  final String endTimeDisplay;
  final int sortOrder;

  DeliverySlotModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.cutoffTime,
    required this.startTimeDisplay,
    required this.endTimeDisplay,
    required this.sortOrder,
  });

  factory DeliverySlotModel.fromJson(Map<String, dynamic> json) {
    return DeliverySlotModel(
      id: json['id'],
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      cutoffTime: json['cutoff_time'] ?? '',
      startTimeDisplay: json['start_time_display'] ?? '',
      endTimeDisplay: json['end_time_display'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  String get displayRange => '$startTimeDisplay - $endTimeDisplay';

  get end_time_display => null;
}
