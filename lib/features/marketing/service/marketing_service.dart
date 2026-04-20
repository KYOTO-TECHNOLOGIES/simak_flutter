import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';

import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';

class MarketingService {
  final Dio _dio = ApiClient().dio;

  Future<List<MarketingModel>> fetchMarketingMedia() async {
    try {
      final response = await _dio.get('marketing/media/');
      final data = response.data;
      
      if (data is List) {
        return data.map((e) => MarketingModel.fromJson(e)).toList();
      } else if (data is Map<String, dynamic> && data.containsKey('results')) {
        return (data['results'] as List)
            .map((e) => MarketingModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DeliveryOfferModel>> fetchDeliveryOffers() async {
    try {
      final response = await _dio.get('marketing/promotional/delivery_offers/');
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        return [DeliveryOfferModel.fromJson(data)];
      } else if (data is List) {
        return data.map((e) => DeliveryOfferModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
