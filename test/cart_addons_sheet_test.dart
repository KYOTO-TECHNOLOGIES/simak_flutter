import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';
import 'package:uae_ecom_project/features/cart/screens/cart_addons_sheet.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

void main() {
  testWidgets(
    'editor starts with saved counts, respects limits, and can remove all addons',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final addon = ProductAddon(
        id: 8,
        name: 'Rice',
        extraPrice: 3,
        maxQuantity: 2,
      );
      final item = CartItemModel(
        id: 42,
        product: ProductModel(
          id: 10,
          name: 'Fish',
          description: '',
          price: 20,
          stock: 10,
          addons: [addon],
        ),
        quantity: 5,
        subtotal: 103,
        addons: [CartAddonModel(addon: addon, quantity: 1, lineExtraPrice: 3)],
      );
      Map<int, int>? result;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      onPressed: () async {
                        result = await showModalBottomSheet<Map<int, int>>(
                          context: context,
                          builder: (_) => CartAddonsSheet(item: item),
                        );
                      },
                      child: const Text('Open'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase addon quantity'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Increase addon quantity',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Decrease addon quantity'));
      await tester.pump();
      await tester.tap(find.byTooltip('Decrease addon quantity'));
      await tester.pump();
      await tester.tap(find.text('Save add-ons'));
      await tester.pumpAndSettle();
      expect(result, {8: 0});
      expect(item.quantity, 5);
      expect(item.addons.single.quantity, 1);
    },
  );
}
