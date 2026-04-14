import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/features/profile/model/notification_model.dart';
import 'package:uae_ecom_project/service/notification_service.dart';

/// Controller that manages in-app notification state.
class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get readCount   => _notifications.where((n) => n.isRead).length;

  // ─── Fetch ──────────────────────────────────────────────────
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getNotifications();
      _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      // Sort newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠ Failed to fetch notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Mark Single as Read ────────────────────────────────────
  Future<void> markAsRead(int notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      // Optimistic update
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWithRead();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠ Failed to mark notification $notificationId as read: $e');
    }
  }

  // ─── Mark All as Read ───────────────────────────────────────
  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      // Optimistic update
      _notifications = _notifications.map((n) => n.copyWithRead()).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠ Failed to mark all notifications as read: $e');
    }
  }

  // ─── Delete ─────────────────────────────────────────────────
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
      // Optimistic update
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠ Failed to delete notification $notificationId: $e');
    }
  }
}
