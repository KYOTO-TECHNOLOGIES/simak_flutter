import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/features/profile/model/notification_model.dart';
import 'package:uae_ecom_project/service/notification_service.dart';

/// Controller that manages in-app notification state.
class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNext = true;
  int _offset = 0;
  final int _limit = 20;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNext => _hasNext;
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
    _offset = 0;
    _hasNext = true;
    notifyListeners();

    try {
      final data = await _service.getNotifications(limit: _limit, offset: 0);
      final List<Map<String, dynamic>> results = data['results'];
      _hasNext = data['hasNext'];
      
      _notifications = results.map((json) => NotificationModel.fromJson(json)).toList();
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _offset = results.length;
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠ Failed to fetch notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreNotifications() async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getNotifications(limit: _limit, offset: _offset);
      final List<Map<String, dynamic>> results = data['results'];
      _hasNext = data['hasNext'];

      if (results.isNotEmpty) {
        final newItems = results.map((json) => NotificationModel.fromJson(json)).toList();
        _notifications.addAll(newItems);
        // Resort or just append? The backend usually returns sorted, but we ensure consistency.
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _offset += results.length;
      }
    } catch (e) {
      debugPrint('⚠ Failed to fetch more notifications: $e');
    } finally {
      _isLoadingMore = false;
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
