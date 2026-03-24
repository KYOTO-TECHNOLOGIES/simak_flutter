import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/screens/otp_screen.dart';
import 'package:uae_ecom_project/features/auth/screens/register_screen.dart';
import 'package:uae_ecom_project/features/home/home_shell.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/checkout_controller.dart';
import 'package:uae_ecom_project/features/orders/screens/order_page.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/splash/splash_screen.dart';
import 'package:uae_ecom_project/service/token_storage.dart';
import 'package:uae_ecom_project/service/cache_service.dart';
import 'package:uae_ecom_project/core/theme/theme_provider.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/cart/screens/cart_screen.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/localization/language_selection_screen.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/orders/screens/order_success_screen.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/marketing/controller/marketing_controller.dart';
import 'package:uae_ecom_project/core/network/connectivity_provider.dart';
import 'package:uae_ecom_project/core/error/no_internet_screen.dart';

import 'package:uae_ecom_project/core/error/error_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenStorage().init();
  // Initialize Hive cache before the app starts.
  await CacheService().init();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

   @override
  void initState() {
    super.initState();
    setupFCM();
  }

  void setupFCM() async {
    // 🔔 Ask permission (important for Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission();

    // 📱 Get token
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");

    // 📩 Listen for messages (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notification Received!");
      print(message.notification?.title);
      print(message.notification?.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AddressController()..fetchAddresses()),
        ChangeNotifierProvider(create: (_) => CheckoutController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => MarketingController()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                '${tr(context, 'app_name_simak')}${tr(context, 'app_name_fresh')}',
            debugShowCheckedModeBanner: false,
            theme: AppColors.lightTheme,
            themeMode: ThemeMode.light,
            locale: langProvider.currentLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('zh', 'CN'),
              Locale('ar', 'AE'),
            ],
            initialRoute: '/',
            routes: {
              '/': (_) => const SplashScreen(),
              '/language_selection': (_) => const LanguageSelectionScreen(),
              '/register': (_) => const RegisterScreen(),
              '/otp': (_) => const OtpScreen(),
              '/home': (_) => const HomeShell(),
              '/cart': (_) => const CartScreen(),
              '/order': (_) => OrderPage(product: ProductModel.empty()),
              '/order-success': (context) {
                final orderData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return OrderSuccessScreen(orderData: orderData);
              },
              '/error': (_) => const ErrorScreen(),
            },
            builder: (context, child) {
              return Consumer<ConnectivityProvider>(
                builder: (context, connectivity, _) {
                  // Only show the no-internet screen when offline
                  // AND there is no cached data to fall back to.
                  final hasCachedProducts =
                      CacheService().hasCache('products');
                  return Stack(
                    children: [
                      if (child != null) child,
                      if (!connectivity.isOnline && !hasCachedProducts)
                        const PremiumNoInternetScreen(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
