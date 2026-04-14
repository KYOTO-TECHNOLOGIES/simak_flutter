/// Model representing a single in-app notification from the backend.
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  /// Order ID extracted from [actionUrl] (e.g. "/orders/195" → 195).
  /// Null when the notification is not order-related.
  final int? orderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actionUrl = json['action_url']?.toString();

    // Extract order ID from action_url like "/orders/195"
    int? orderId;
    if (actionUrl != null && actionUrl.isNotEmpty) {
      final match = RegExp(r'/orders/(\d+)').firstMatch(actionUrl);
      if (match != null) {
        orderId = int.tryParse(match.group(1)!);
      }
    }

    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      actionUrl: actionUrl,
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      orderId: orderId,
    );
  }

  /// Returns a copy with [isRead] set to true.
  NotificationModel copyWithRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      actionUrl: actionUrl,
      isRead: true,
      createdAt: createdAt,
      orderId: orderId,
    );
  }
}
