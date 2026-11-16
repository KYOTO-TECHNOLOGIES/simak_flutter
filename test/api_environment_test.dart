import 'package:flutter_test/flutter_test.dart';
import 'package:uae_ecom_project/core/config/env.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

void main() {
  const expectedHost = String.fromEnvironment(
    'EXPECTED_API_HOST',
    defaultValue: 'stage.simakfresh.ae',
  );

  test('API and relative media use the selected build environment', () {
    final api = Uri.parse(Env.baseUrl);
    expect(api.scheme, 'https');
    expect(api.host, expectedHost);
    expect(api.path, '/api/');
    final image = Uri.parse(
      ProductModel.getAbsoluteUrl('/media/product_addons/rice.jpg'),
    );
    expect(image.host, expectedHost);
    expect(image.path, '/media/product_addons/rice.jpg');
    expect(
      ProductModel.getAbsoluteUrl('https://cdn.example.com/rice.jpg'),
      'https://cdn.example.com/rice.jpg',
    );
  });
}
