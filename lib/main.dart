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
import 'package:uae_ecom_project/features/orders/controller/coupon_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/checkout_controller.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/orders/screens/order_page.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/splash/splash_screen.dart';
import 'package:uae_ecom_project/features/delivery/screens/delivery_dashboard_screen.dart';
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
import 'package:uae_ecom_project/features/delivery/screens/delivery_profile_screen.dart';
import 'package:uae_ecom_project/core/widgets/delivery_guard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenStorage().init();
  await CacheService().init();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

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
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Deep Link Error: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('Deep Link Stream Error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Captured Deep Link: $uri');

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

  // void setupFCM() async {
  //   //  Ask permission (important for Android 13+ / iOS)
  //   await FirebaseMessaging.instance.requestPermission();

  //   final notificationService = NotificationService();

  //   //  Initial Sync
  //   notificationService.syncToken();

  //   //  Listen for token refresh and re-register
  //   FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  //     debugPrint("FCM TOKEN REFRESHED: $newToken");
  //     notificationService.syncToken();
  //   });

  //   //  Listen for messages (when app is open)
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     debugPrint("Notification Received!");
  //     debugPrint(message.notification?.title);
  //     debugPrint(message.notification?.body);
  //   });
  // }

  void setupFCM() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    debugPrint("Permission Status: ${settings.authorizationStatus}");

    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN => $token");

    final notificationService = NotificationService();
    notificationService.syncToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("FCM TOKEN REFRESHED => $newToken");
      notificationService.syncToken();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Notification Received!");
      debugPrint(message.notification?.title);
      debugPrint(message.notification?.body);
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
        ChangeNotifierProvider(
          create: (_) => AddressController()..fetchAddresses(),
        ),
        ChangeNotifierProvider(create: (_) => CheckoutController()..init()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => MarketingController()),
        ChangeNotifierProvider(create: (_) => EmirateController()..init()),
        ChangeNotifierProvider(create: (_) => SystemController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => CouponController()),
        ChangeNotifierProvider(create: (_) => DeliveryController()),
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
              '/login': (_) => const LoginRedirect(),
              '/emirate_selection': (_) => const EmirateSelectionScreen(),
              '/register': (_) => const RegisterScreen(),
              '/otp': (_) => const OtpScreen(),
              '/home': (_) => const DeliveryUserGuard(child: HomeShell()),
              '/cart': (_) => const DeliveryUserGuard(child: CartScreen()),
              '/order': (_) => DeliveryUserGuard(
                child: OrderPage(product: ProductModel.empty()),
              ),
              '/order-success': (context) {
                final orderData =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                return OrderSuccessScreen(orderData: orderData);
              },
              '/order-pending': (context) {
                final String orderId =
                    ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return OrderPendingScreen(orderId: orderId);
              },
              '/payment-failed': (context) {
                final String orderId =
                    ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return PaymentFailedScreen(orderId: orderId);
              },
              '/payment-success': (context) {
                final String orderId =
                    ModalRoute.of(context)!.settings.arguments as String? ?? '';
                return PaymentSuccessScreen(orderId: orderId);
              },
              '/delivery_dashboard': (_) => const DeliveryDashboardScreen(),
              '/delivery_profile': (_) => const DeliveryProfileScreen(),
              '/error': (_) => const ErrorScreen(),
            },
            builder: (context, child) {
              return Consumer<ConnectivityProvider>(
                builder: (context, connectivity, __) {
                  final hasCachedProducts = CacheService().hasCache('products');
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

class LoginRedirect extends StatelessWidget {
  const LoginRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/home', arguments: 2);
    });
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.actionBlue),
      ),
    );
  }
}
