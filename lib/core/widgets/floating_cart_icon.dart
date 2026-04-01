import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class FloatingCartIcon extends StatelessWidget {
  const FloatingCartIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return const SizedBox.shrink();

        return Consumer<CartController>(
          builder: (context, controller, child) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/cart');
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The main cart vessel
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          // Fixed premium shadow
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  
                  // Badge
                  if (controller.uniqueItemCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${controller.uniqueItemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
