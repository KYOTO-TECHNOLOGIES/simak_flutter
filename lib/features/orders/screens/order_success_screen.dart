import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderSuccessScreen({super.key, required this.orderData});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Redirect to home after 4 seconds
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderData['order_id'] ?? widget.orderData['id'] ?? 'N/A';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7), // Light greenish background from screenshot
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4F1E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF1CB58A),
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Success Text
                Text(
                  tr(context, 'order_placed_successfully') != 'order_placed_successfully' 
                      ? tr(context, 'order_placed_successfully') 
                      : 'Order Placed Successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Order ID
                Text(
                  '${tr(context, 'order_id_label')} $orderId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Subtext
                Text(
                  tr(context, 'order_preparing_subtext') != 'order_preparing_subtext'
                      ? tr(context, 'order_preparing_subtext')
                      : 'Thank you for your fresh catch. We\'re preparing it now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Redirect text
                Text(
                  tr(context, 'redirecting_home') != 'redirecting_home'
                      ? tr(context, 'redirecting_home')
                      : 'Redirecting to home...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
