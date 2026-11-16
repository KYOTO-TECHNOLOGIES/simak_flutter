import 'package:flutter_test/flutter_test.dart';
import 'package:uae_ecom_project/core/localization/catalog_localization.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/model/category_model.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';

void main() {
  tearDown(() => CatalogLocalization.locale = 'en');

  test('cached catalog switches EN/AR/CN without fetching again', () {
    final product = ProductModel.fromJson({
      'id': 1,
      'name': 'Grilled fish',
      'name_arabic': 'سمك مشوي',
      'name_chinese': '烤鱼',
      'description': 'Fresh fish',
      'description_arabic': 'سمك طازج',
      'description_chinese': '新鲜鱼',
      'category_name': 'GRILL & FRY FISH',
      'preparation_specifications': [
        {'id': 2, 'name': 'Whole', 'name_arabic': 'كامل', 'name_chinese': '整条'},
      ],
      'addons': [
        {
          'id': 3,
          'name': 'Mayonnaise',
          'name_arabic': 'مايونيز',
          'name_chinese': '蛋黄酱',
          'extra_price': '2.50',
          'max_quantity': 2,
          'is_active': true,
        },
      ],
    });
    expect(product.name, 'Grilled fish');
    CatalogLocalization.locale = 'ar';
    expect(product.name, 'سمك مشوي');
    expect(product.description, 'سمك طازج');
    expect(product.preparationSpecifications.single.name, 'كامل');
    expect(product.addons.single.name, 'مايونيز');
    CatalogLocalization.locale = 'cn';
    expect(product.name, '烤鱼');
    expect(product.description, '新鲜鱼');
    expect(product.preparationSpecifications.single.name, '整条');
    expect(product.addons.single.name, '蛋黄酱');
    expect(product.categoryName, 'GRILL & FRY FISH');
    CatalogLocalization.locale = 'en';
    expect(product.name, 'Grilled fish');
  });

  test('missing, blank and whitespace translations fall back to English', () {
    final product = ProductModel.fromJson({
      'id': 1,
      'name': 'Fish',
      'description': 'Fresh',
      'name_arabic': '  ',
      'description_arabic': null,
      'name_chinese': '',
    });
    for (final locale in ['ar', 'cn']) {
      CatalogLocalization.locale = locale;
      expect(product.name, 'Fish');
      expect(product.description, 'Fresh');
    }
    expect(
      PreparationSpecification.fromJson({'id': 1, 'name': 'Whole'}).description,
      isNull,
    );
  });

  test(
    'category display translates while its API filter name stays English',
    () {
      final category = CategoryModel.fromJson({
        'id': 1,
        'name': 'Grill & Fry',
        'name_arabic': 'مشوي ومقلي',
        'name_chinese': '烤和炸',
      });
      expect(category.getLocalizedName('ar'), 'مشوي ومقلي');
      expect(category.getLocalizedName('cn'), '烤和炸');
      expect(category.name, 'Grill & Fry');
    },
  );

  test('marketing titles, descriptions, highlights and CTA use admin text', () {
    final banner = MarketingModel.fromJson({
      'id': 1,
      'title': 'Fish',
      'title_arabic': 'سمك',
      'subtitle': '',
      'description': 'Fresh',
      'description_arabic': 'طازج',
      'highlight': 'Offer',
      'highlight_arabic': 'عرض',
      'cta': 'Shop now',
      'cta_arabic': 'تسوق الآن',
    });
    CatalogLocalization.locale = 'ar';
    expect(banner.title, 'سمك');
    expect(banner.subtitle, 'طازج');
    expect(banner.tag, 'عرض');
    expect(banner.ctaText, 'تسوق الآن');
    CatalogLocalization.locale = 'en';
    expect(banner.title, 'Fish');
    expect(banner.ctaText, 'Shop now');
  });

  test(
    'cart retains server totals, preparation and selected addon quantities',
    () {
      final item = CartItemModel.fromJson({
        'id': 7,
        'product': 1,
        'product_details': {'id': 1, 'name': 'Fish', 'final_price': '20.00'},
        'quantity': 2,
        'subtotal': '54.00',
        'preparation_specification': 2,
        'preparation_specification_details': {
          'id': 2,
          'name': 'Whole',
          'name_chinese': '整条',
        },
        'addons': [
          {
            'addon': 3,
            'quantity': 2,
            'line_extra_price': '5.00',
            'addon_details': {
              'id': 3,
              'name': 'Mayo',
              'name_chinese': '蛋黄酱',
              'extra_price': '2.50',
            },
          },
        ],
      });
      expect(item.subtotal, 54);
      expect(item.addons.single.quantity, 2);
      expect(item.addons.single.lineExtraPrice, 5);
      CatalogLocalization.locale = 'cn';
      expect(item.preparationSpecificationName, '整条');
      expect(item.addons.single.addon.name, '蛋黄酱');
    },
  );
}
