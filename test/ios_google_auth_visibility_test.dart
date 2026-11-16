import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/widgets/unified_auth_form.dart';
import 'package:uae_ecom_project/features/auth/widgets/unified_register_form.dart';

void main() {
  Future<void> showForm(WidgetTester tester, Widget form) async {
    SharedPreferences.setMockInitialValues({'selectedLocale_v2': 'en'});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AuthController()),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: form)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'iOS registration hides Google button and its divider',
    (tester) async {
      await showForm(tester, const UnifiedRegisterForm());
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(Divider), findsNothing);
      expect(find.byType(ElevatedButton), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS login keeps Google sign-in hidden',
    (tester) async {
      await showForm(tester, const UnifiedAuthForm());
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(ElevatedButton), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android registration retains its Google sign-in button',
    (tester) async {
      await showForm(tester, const UnifiedRegisterForm());
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
