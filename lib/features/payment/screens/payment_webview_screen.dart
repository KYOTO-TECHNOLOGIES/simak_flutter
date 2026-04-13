import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Payment',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.scheme == 'myapp') {
              debugPrint('Intercepted Deep Link in WebView: $uri');
              _handleDeepLink(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Resource Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }
  
  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'myapp' && uri.host == 'payment') {
      final String path = uri.path;
      final String orderId = uri.queryParameters['order_id'] ?? '';
      
      if (path == '/success') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment-success',
          (route) => route.isFirst,
          arguments: orderId,
        );
      } else if (path == '/cancel') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment-failed', 
          (route) => route.isFirst,
          arguments: orderId,
        );
      } else if (path == '/pending') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-pending',
          (route) => route.isFirst,
          arguments: orderId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
