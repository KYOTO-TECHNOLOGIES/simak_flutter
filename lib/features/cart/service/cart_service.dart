import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';
import 'package:uae_ecom_project/features/cart/model/cart_model.dart';

class CartService {
  final Dio _dio = ApiClient().dio;

  Future<CartModel> fetchCart() async {
    try {
      final url = 'cart/my_cart/';
      debugPrint('Base URL: ${_dio.options.baseUrl}');
      debugPrint('GET Request to: $url');
      final response = await _dio.get(url);
      final data = response.data;
      debugPrint('GET Response data type: ${data.runtimeType}');
      
      if (data is List) {
        final items = data.map((e) => CartItemModel.fromJson(e)).toList();
        return CartModel(
          items: items,
          totalPrice: items.fold(0.0, (sum, item) => sum + item.subtotal),
          totalItems: items.length,
        );
      }
      
      return CartModel.fromJson(data is Map<String, dynamic> ? data : {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addItem(int productId, int quantity) async {
    try {
      final url = 'cart/add_item/';
      final data = {
        'product': productId,
        'quantity': quantity,
      };
      debugPrint('POST Request to: $url');
      debugPrint('Payload: $data');
      await _dio.post(url, data: data);
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      await _dio.post('cart/update_item_quantity/', data: {
        'product': productId,
        'quantity': quantity,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      await _dio.post('cart/remove_item/', data: {
        'product': productId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.post('cart/clear/');
    } catch (e) {
      rethrow;
    }
  }
}
