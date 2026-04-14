import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'dart:async';
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
import 'package:uae_ecom_project/firebase_options.dart';
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
import 'package:uae_ecom_project/features/orders/screens/order_pending_screen.dart';
import 'package:uae_ecom_project/features/orders/screens/payment_failed_screen.dart';
import 'package:uae_ecom_project/features/orders/screens/payment_success_screen.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/marketing/controller/marketing_controller.dart';
import 'package:uae_ecom_project/core/network/connectivity_provider.dart';
import 'package:uae_ecom_project/core/error/no_internet_screen.dart';
import 'package:uae_ecom_project/features/emirate/controller/emirate_controller.dart';
import 'package:uae_ecom_project/features/emirate/screens/emirate_selection_screen.dart';
import 'package:uae_ecom_project/features/auth/controller/system_controller.dart';
import 'package:uae_ecom_project/core/error/error_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:uae_ecom_project/service/notification_service.dart';
import 'package:uae_ecom_project/features/profile/controller/notification_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint("Background message: ${message.notification?.title}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenStorage().init();
  // Initialize Hive cache before the app starts.
  await CacheService().init();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  // Register background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await TokenStorage().init();
  await CacheService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  StreamSubscription? _sub;
  final _appLinks = AppLinks();

   @override
  void initState() {
    super.initState();
    setupFCM();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // 1. Handle initial link (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Deep Link Error: $e');
    }

    // 2. Handle subsequent links (app in background/foreground)
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('Deep Link Stream Error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Captured Deep Link: $uri');
    
    // Only handle myapp://payment links
    if (uri.scheme == 'myapp' && uri.host == 'payment') {
      final String path = uri.path;
      final String orderId = uri.queryParameters['order_id'] ?? '';
      
      if (path == '/success') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/payment-success',
          (route) => route.isFirst,
          arguments: orderId,
        );
      } else if (path == '/cancel') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/payment-failed', 
          (route) => route.isFirst,
          arguments: orderId,
        );
      } else if (path == '/pending') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/order-pending',
          (route) => route.isFirst,
          arguments: orderId,
        );
      }
    }
  }

  void setupFCM() async {
    // 🔔 Ask permission (important for Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission();

    // 📱 Get token
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $token");

    // 📤 Register the device with the backend for push notifications
    if (token != null) {
      _registerDeviceToken(token);
    }

    // 🔄 Listen for token refresh and re-register
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("FCM TOKEN REFRESHED: $newToken");
      _registerDeviceToken(newToken);
    });

    // 📩 Listen for messages (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Notification Received!");
      debugPrint(message.notification?.title);
      debugPrint(message.notification?.body);
    });
  }

  /// Sends the FCM [token] to the backend so it can target this device.
  Future<void> _registerDeviceToken(String token) async {
    try {
      final notificationService = NotificationService();
      final response = await notificationService.registerDevice(
        registrationToken: token,
        deviceType: NotificationService.resolveDeviceType(),
        deviceName: NotificationService.resolveDeviceName(),
      );
      debugPrint("✅ Device registered for push notifications: $response");
    } catch (e) {
      debugPrint("⚠ Failed to register device for push notifications: $e");
    }
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
        ChangeNotifierProvider(create: (_) => CheckoutController()..init()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => MarketingController()),
        ChangeNotifierProvider(create: (_) => EmirateController()..init()),
        ChangeNotifierProvider(create: (_) => SystemController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
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
              '/emirate_selection': (_) => const EmirateSelectionScreen(),
              '/register': (_) => const RegisterScreen(),
              '/otp': (_) => const OtpScreen(),
              '/home': (_) => const HomeShell(),
              '/cart': (_) => const CartScreen(),
              '/order': (_) => OrderPage(product: ProductModel.empty()),
              '/order-success': (context) {
                final orderData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return OrderSuccessScreen(orderData: orderData);
              },
              '/order-pending': (context) {
                final String orderId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return OrderPendingScreen(orderId: orderId);
              },
              '/payment-failed': (context) {
                final String orderId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return PaymentFailedScreen(orderId: orderId);
              },
              '/payment-success': (context) {
                final String orderId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return PaymentSuccessScreen(orderId: orderId);
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
