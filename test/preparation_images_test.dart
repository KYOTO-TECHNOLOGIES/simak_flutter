import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/core/widgets/prep_selection_sheet.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

void main() {
  testWidgets(
    'preparation modal shows the supplied image and still selects it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      int? selected;
      final product = ProductModel(
        id: 1,
        name: 'Fish',
        description: '',
        price: 20,
        stock: 10,
        preparationSpecifications: [
          PreparationSpecification(
            id: 8,
            name: 'Whole',
            image: 'assets/images/home_logo.png',
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: PrepSelectionSheet(
                product: product,
                onSelected: (id, instructions) => selected = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomImage), findsOneWidget);
      expect(
        tester.widget<CustomImage>(find.byType(CustomImage)).url,
        'assets/images/home_logo.png',
      );
      await tester.tap(find.text('Whole'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      expect(selected, 8);
    },
  );
}
