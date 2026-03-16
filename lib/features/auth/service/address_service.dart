import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';

class AddressService {
  final Dio _dio = ApiClient().dio;

  Future<List<AddressModel>> fetchAddresses() async {
    try {
      final response = await _dio.get('addresses/');
      final dynamic data = response.data;
      
      if (data is List) {
        return data.map((json) => AddressModel.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        return (data['results'] as List).map((json) => AddressModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('AddressService.fetchAddresses Error: $e');
      return [];
    }
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      final data = address.toJson();
      debugPrint('AddressService.createAddress REQUEST DATA: $data');
      final response = await _dio.post(
        'addresses/',
        data: data,
      );
      return AddressModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('AddressService.createAddress ERROR BODY: ${e.response?.data}');
      }
      debugPrint('AddressService.createAddress Error: $e');
      rethrow;
    }
  }

  Future<AddressModel> updateAddress(String id, AddressModel address) async {
    final response = await _dio.put(
      'addresses/$id/',
      data: address.toJson(),
    );
    return AddressModel.fromJson(response.data);
  }

  Future<AddressModel> patchAddress(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      'addresses/$id/',
      data: data,
    );
    return AddressModel.fromJson(response.data);
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('addresses/$id/');
  }
}
