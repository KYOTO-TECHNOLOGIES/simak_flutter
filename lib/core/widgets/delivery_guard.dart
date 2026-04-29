import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class DeliveryUserGuard extends StatelessWidget {
  final Widget child;

  const DeliveryUserGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // If the user is a delivery partner, prevent them from accessing customer-facing pages
    if (auth.isLoggedIn && auth.isDeliveryUser) {
      // Schedule the navigation for the next frame to avoid building while navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear navigation stack and force redirect to delivery dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/delivery_dashboard',
          (route) => false,
        );
      });

      // Show a loading/placeholder screen while the redirect happens
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF007AFF), // AppColors.actionBlue equivalent
          ),
        ),
      );
    }

    return child;
  }
}
