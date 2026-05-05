import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/delivery/model/delivery_model.dart';
import 'package:uae_ecom_project/features/delivery/service/delivery_service.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';

class DeliveryController with ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService();

  DeliveryDashboardData? _dashboardData;
  DeliveryDashboardData? get dashboardData => _dashboardData;

  List<OrderModel> _availableOrders = [];
  List<OrderModel> get availableOrders => _availableOrders;

  bool _isLoadingDashboard = false;
  bool get isLoadingDashboard => _isLoadingDashboard;

  bool _isLoadingAvailableOrders = false;
  bool get isLoadingAvailableOrders => _isLoadingAvailableOrders;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboard({bool silent = false}) async {
    if (!silent) {
      _isLoadingDashboard = true;
      notifyListeners();
    }
    _error = null;

    try {
      _dashboardData = await _deliveryService.getDeliveryDashboard();
      
      // Dashboard also needs to call available orders with limit 6
      _availableOrders = await _deliveryService.getAvailableOrders(limit: 6, offset: 0);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoadingDashboard = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchAvailableOrders({int? limit, int? offset, bool silent = false}) async {
    if (!silent) {
      _isLoadingAvailableOrders = true;
      notifyListeners();
    }
    _error = null;

    try {
      _availableOrders = await _deliveryService.getAvailableOrders(limit: limit, offset: offset);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoadingAvailableOrders = false;
      }
      notifyListeners();
    }
  }

  Future<bool> claimOrder(int orderId, {String? notes}) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _deliveryService.claimOrder(orderId, notes: notes);
      await fetchDashboard(silent: true);
      await fetchAvailableOrders(silent: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(
    int orderId,
    String status, {
    File? proofImage,
    String? signatureName,
    String? proofNotes,
    String? notes,
    String? cancelReason,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _deliveryService.updateDeliveryStatus(
        orderId,
        status,
        proofImage: proofImage,
        signatureName: signatureName,
        proofNotes: proofNotes,
        notes: notes,
        cancelReason: cancelReason,
      );
      await fetchDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
