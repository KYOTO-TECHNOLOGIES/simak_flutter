import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

class ProductService {
  final Dio _dio = ApiClient().dio;

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await _dio.get('products/products/');
      
      // Handle pagination result if API returns { "results": [...] }
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return (data['results'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
      } else if (data is List) {
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductModel> fetchProductDetail(int id) async {
    try {
      final response = await _dio.get('products/products/$id/');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
