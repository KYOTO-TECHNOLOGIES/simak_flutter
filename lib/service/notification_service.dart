import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uae_ecom_project/service/token_storage.dart';

/// Service for push-notification device registration and in-app notifications.
class NotificationService {
  final Dio _dio = ApiClient().dio;

  // ═════════════════════════════════════════════════════════════════
  //  DEVICE REGISTRATION
  // ═════════════════════════════════════════════════════════════════

  /// Synchronizes the current FCM token with the backend.
  /// Should be called on app start, token refresh, and user login.
  Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Only register if we have a valid session, otherwise the API returns 401
        if (TokenStorage().isLoggedIn) {
          await _registerWithToken(token);
        } else {
          debugPrint("⏭ Skipping FCM Sync: User not authenticated.");
        }
      }
    } catch (e) {
      debugPrint("⚠ FCM Sync failed: $e");
    }
  }

  Future<void> _registerWithToken(String token) async {
    try {
      await registerDevice(
        registrationToken: token,
        deviceType: resolveDeviceType(),
        deviceName: resolveDeviceName(),
      );
      debugPrint("✅ Device registered for push notifications successfully.");
    } catch (e) {
      debugPrint("⚠ Device registration API failed: $e");
    }
  }

  /// Registers the device with the backend for push notifications.
  ///
  /// Sends the FCM [registrationToken], [deviceType], and [deviceName]
  /// to `POST /api/notifications/devices/`.
  /// The Authorization header is attached automatically by [ApiClient].
  Future<Map<String, dynamic>> registerDevice({
    required String registrationToken,
    required String deviceType,
    required String deviceName,
  }) async {
    final response = await _dio.post(
      'notifications/devices/',
      data: {
        'registration_token': registrationToken,
        'device_type': deviceType,
        'device_name': deviceName,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ═════════════════════════════════════════════════════════════════
  //  IN-APP NOTIFICATIONS
  // ═════════════════════════════════════════════════════════════════

  /// Fetches notifications for the authenticated user.
  /// GET /api/notifications/?limit=20&offset=0
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      'notifications/',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    
    List<Map<String, dynamic>> results = [];
    bool hasNext = false;

    // Paginated response: { count, next, previous, results: [...] }
    if (data is Map<String, dynamic>) {
      if (data['results'] is List) {
        results = (data['results'] as List).cast<Map<String, dynamic>>();
      }
      hasNext = data['next'] != null;
    } else if (data is List) {
      results = data.cast<Map<String, dynamic>>();
      hasNext = false;
    }

    return {
      'results': results,
      'hasNext': hasNext,
    };
  }

  /// Marks a single notification as read.
  /// POST /api/notifications/{id}/mark_as_read/
  Future<void> markAsRead(int notificationId) async {
    await _dio.post('notifications/$notificationId/mark_as_read/');
  }

  /// Marks all notifications as read.
  /// POST /api/notifications/mark_all_as_read/
  Future<void> markAllAsRead() async {
    await _dio.post('notifications/mark_all_as_read/');
  }

  /// Deletes a single notification.
  /// DELETE /api/notifications/{id}/
  Future<void> deleteNotification(int notificationId) async {
    await _dio.delete('notifications/$notificationId/');
  }

  // ─── Helpers ──────────────────────────────────────────────────

  /// Returns the device type string based on the current platform.
  static String resolveDeviceType() {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'WEB'; // fallback
  }

  /// Returns a human-readable device name for the current platform.
  static String resolveDeviceName() {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'Unknown Device';
  }
}
