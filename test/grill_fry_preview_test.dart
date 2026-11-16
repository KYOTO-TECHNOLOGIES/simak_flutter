import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/emirate/controller/emirate_controller.dart';
import 'package:uae_ecom_project/features/grill_fry/data/grill_fry_dummy_data.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/products_page.dart';

// Sample catalog only for the preview; the app continues to use backend products.
class PreviewProducts extends ProductController {
  @override
  List<ProductModel> get products => GrillFryDummyData.products;
  @override
  List<ProductModel> get filteredProducts => products;
  @override
  String get selectedCategory => 'GRILL & FRY';
  @override
  Future<void> fetchProducts({
    String? emirate,
    String? categoryName,
    bool forceRefresh = false,
  }) async {}
  @override
  Future<void> fetchCategories() async {}
}

File sdkFont(String filename) {
  var directory = File(Platform.resolvedExecutable).parent;
  while (true) {
    final font = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/$filename',
    );
    if (font.existsSync()) return font;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Cannot locate Flutter SDK font: $filename');
    }
    directory = parent;
  }
}

void main() {
  testWidgets('Grill and Fry category preview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Roboto');
    font.addFont(
      Future.value(
        ByteData.sublistView(sdkFont('Roboto-Regular.ttf').readAsBytesSync()),
      ),
    );
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      Future.value(
        ByteData.sublistView(
          sdkFont('MaterialIcons-Regular.otf').readAsBytesSync(),
        ),
      ),
    );
    await icons.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<ProductController>(
            create: (_) => PreviewProducts(),
          ),
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => EmirateController()),
        ],
        child: MaterialApp(
          theme: AppColors.lightTheme.copyWith(
            textTheme: ThemeData(fontFamily: 'Roboto').textTheme,
          ),
          home: const Scaffold(
            body: RepaintBoundary(
              key: ValueKey('preview'),
              child: ProductsPage(),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ProductsPage));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/grill_and_fry.jpg'),
          context,
        ),
        precacheImage(const AssetImage('assets/images/home_logo.png'), context),
        for (final product in GrillFryDummyData.products)
          precacheImage(AssetImage(product.mainImage!), context),
      ]);
    });
    await tester.pumpAndSettle();
    expect(find.text('GRILL & FRY'), findsWidgets);
    expect(tester.takeException(), isNull);
    // Pixel comparison is opt-in because SDK/platform rendering can differ in CI.
    if (const bool.fromEnvironment('CHECK_GRILL_PREVIEW')) {
      await expectLater(
        find.byKey(const ValueKey('preview')),
        matchesGoldenFile('../docs/previews/grill-fry-category.png'),
      );
    }
  });
}
