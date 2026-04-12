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
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Dynamic check for success/failure in URL
            // Many gateways redirect to a success page after completion
            if (url.contains('success') || url.contains('completed') || url.contains('thank-you')) {
              // Give the user a moment to see the success message on the web page if needed
              // or just pop back to the app success screen
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) Navigator.of(context).pop(true);
              });
            } else if (url.contains('fail') || url.contains('error') || url.contains('cancel')) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) Navigator.of(context).pop(false);
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Resource Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
