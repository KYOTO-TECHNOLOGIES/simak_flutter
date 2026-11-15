import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/cart/service/cart_service.dart';
import 'package:uae_ecom_project/service/token_storage.dart';

class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{}',
      201,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingAdapter adapter;
  late HttpClientAdapter previousAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage().init();
    adapter = RecordingAdapter();
    previousAdapter = ApiClient().dio.httpClientAdapter;
    ApiClient().dio.httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient().dio.httpClientAdapter = previousAdapter);

  test(
    'cart request matches staging addons contract alongside preparation',
    () async {
      await CartService().addItem(
        10,
        2,
        preparationSpecificationId: 4,
        preparationInstructions: 'Less salt',
        addonQuantities: {8: 2, 9: 0, 11: 1},
      );
      final request = adapter.request!;
      expect(request.path, 'cart/add_item/');
      expect(request.data['product'], 10);
      expect(request.data['quantity'], 2);
      expect(request.data['preparation_specification'], 4);
      expect(request.data['preparation_instructions'], 'Less salt');
      expect(request.data['addons'], [
        {'id': 8, 'quantity': 2},
        {'id': 11, 'quantity': 1},
      ]);
      expect(request.data.containsKey('addon_quantities'), false);
      expect(request.headers['Accept-Language'], 'en');
    },
  );

  test('plain product can still be added without addons', () async {
    await CartService().addItem(10, 1);
    expect(adapter.request!.data.containsKey('addons'), false);
  });
}
