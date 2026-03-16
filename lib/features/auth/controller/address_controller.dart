import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';
import 'package:uae_ecom_project/features/auth/service/address_service.dart';

class AddressController extends ChangeNotifier {
  final AddressService _service = AddressService();

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  AddressModel? _selectedAddress;
  AddressModel? get selectedAddress => _selectedAddress;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _service.fetchAddresses();
      if (_addresses.isNotEmpty) {
        _selectedAddress = _addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _addresses.first,
        );
      } else {
        _selectedAddress = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AddressController.fetchAddresses Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAddress = await _service.createAddress(address);
      await fetchAddresses();
      _selectedAddress = newAddress;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('AddressController.addAddress Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      await _service.deleteAddress(id);
      if (_selectedAddress?.id == id) {
        _selectedAddress = null;
      }
      await fetchAddresses();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('AddressController.deleteAddress Error: $e');
      return false;
    }
  }

  void clear() {
    _addresses = [];
    _selectedAddress = null;
    _error = null;
    notifyListeners();
  }
}
