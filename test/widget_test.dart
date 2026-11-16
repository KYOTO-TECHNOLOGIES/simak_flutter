import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/localization/catalog_localization.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

void main() {
  tearDown(() => CatalogLocalization.locale = 'en');

  testWidgets('changing language updates already displayed catalog content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selectedLocale_v2': 'en'});
    final language = LanguageProvider();
    final product = ProductModel.fromJson({
      'id': 1,
      'name': 'Fish',
      'name_arabic': 'سمك',
      'name_chinese': '鱼',
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: language,
        child: MaterialApp(
          home: Consumer<LanguageProvider>(
            builder: (context, language, _) {
              return Directionality(
                textDirection:
                    language.isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: Text(product.name),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fish'), findsOneWidget);
    await language.setLocale('ar');
    await tester.pumpAndSettle();
    expect(find.text('سمك'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: find.text('سمك'),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection,
      TextDirection.rtl,
    );
    await language.setLocale('zh-CN');
    await tester.pumpAndSettle();
    expect(find.text('鱼'), findsOneWidget);
    expect(language.locale, 'cn');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selectedLocale_v2'), 'cn');
    await language.setLocale('en');
    await tester.pumpAndSettle();
    expect(find.text('Fish'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    language.dispose();
  });

  testWidgets('saved language is applied to cached catalog on startup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selectedLocale_v2': 'cn',
      'hasSelectedLanguage_v2': true,
    });
    final language = LanguageProvider();
    await tester.pump();
    expect(language.isInitialized, true);
    expect(CatalogLocalization.locale, 'cn');
    expect(language.hasSelectedLanguage, true);
    language.dispose();
  });
}
