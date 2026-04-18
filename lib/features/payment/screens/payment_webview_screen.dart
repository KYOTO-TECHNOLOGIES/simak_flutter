import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/payment/service/payment_service.dart';
import 'package:uae_ecom_project/features/payment/model/payment_model.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final int? orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Payment',
    this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isVerifying = false;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            debugPrint('WebView Navigating to: $url');

            if (url.toLowerCase().startsWith('myapp://')) {
              debugPrint('Intercepted Deep Link in WebView: $url');
              _handleDeepLink(Uri.parse(url));
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

  Future<void> _handleDeepLink(Uri uri) async {
    // Only handle myapp://payment/... or myapp://...
    if (uri.scheme == 'myapp') {
      String orderIdStr =
          uri.queryParameters['order_id'] ??
          uri.queryParameters['id'] ??
          uri.queryParameters['orderId'] ??
          '';

      if (orderIdStr.isEmpty && widget.orderId != null) {
        orderIdStr = widget.orderId.toString();
      }

      if (orderIdStr.isEmpty) {
        debugPrint('WebView: No order_id found in deep link');
        return;
      }

      setState(() {
        _isVerifying = true;
      });

      try {
        final int? orderId = int.tryParse(orderIdStr);
        if (orderId == null) {
          throw Exception('Invalid order ID format: $orderIdStr');
        }

        // Verify status with backend using the dedicated API
        Map<String, dynamic>? verifyData;
        String status = 'PENDING';
        int retries = 3; // Poll up to 3 times (6 seconds total)

        while (retries > 0) {
          try {
            verifyData = await _paymentService.verifyPayment(orderId);
            if (verifyData != null) {
              status =
                  verifyData['status']?.toString().toUpperCase() ?? 'PENDING';

              // If terminal state reached, stop polling
              if ([
                'SUCCESS',
                'PAID',
                'COMPLETED',
                'FAILED',
                'CANCELLED',
              ].contains(status)) {
                break;
              }
            }
          } catch (e) {
            debugPrint('Verification API failed on attempt ${4 - retries}: $e');
          }

          if (!mounted) return;

          if (retries > 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
          retries--;
        }

        if (!mounted) return;

        debugPrint('Verified Payment Status Final: $status');

        if (status == 'SUCCESS' || status == 'PAID' || status == 'COMPLETED') {
          Navigator.pop(context, 'success');
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          Navigator.pop(context, 'failed');
        } else {
          Navigator.pop(context, 'pending');
        }
      } catch (e) {
        debugPrint('Error verifying payment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().split(':').last.trim()}'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
        }
      }
    }
  }

  Future<void> _handleBackButton() async {
    if (widget.orderId != null) {
      setState(() {
        _isVerifying = true;
      });

      Map<String, dynamic>? verifyData;
      try {
        verifyData = await _paymentService.verifyPayment(widget.orderId!);
      } catch (e) {
        debugPrint('Verification API failed on back button: $e');
      }

      if (!mounted) return;

      if (verifyData != null) {
        final String status =
            verifyData['status']?.toString().toUpperCase() ?? 'PENDING';
        if (status == 'SUCCESS' || status == 'PAID' || status == 'COMPLETED') {
          Navigator.pop(context, 'success');
          return;
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          Navigator.pop(context, 'failed');
          return;
        }
      }

      // If network fails or it's still pending, assume they cancelled by hitting back
      if (mounted) {
        Navigator.pop(context, 'failed');
      }
    } else {
      Navigator.pop(context, 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackButton(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading || _isVerifying)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    if (_isVerifying) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Verifying payment status...',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
