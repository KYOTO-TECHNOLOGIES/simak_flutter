import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/screens/login_screen.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

// ═════════════════════════════════════════════════════════════════════
//  QUICK ADD TO CART BUTTON  —  Shared floating button
// ═════════════════════════════════════════════════════════════════════
class QuickAddToCartButton extends StatelessWidget {
  final ProductModel product;
  final double size;
  final double iconSize;

  const QuickAddToCartButton({
    super.key,
    required this.product,
    this.size = 30,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final bool inStock = product.isAvailable && product.stock > 0;
    
    return GestureDetector(
      onTap: inStock
          ? () async {
              final auth = context.read<AuthController>();
              final cart = context.read<CartController>();

              if (!auth.isLoggedIn) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
                return;
              }

              // Always try to add to cart (increments quantity if already exists)
              final success = await cart.addToCart(product.id, 1);
              
              if (context.mounted) {
                // Clear existing snackbars to show the new one immediately
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                
                final String message = success 
                    ? trStatic(context, 'added_to_cart') 
                    : (cart.error ?? trStatic(context, 'failed_add_cart'));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle_outline : Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.shopping_cart_rounded,
          size: iconSize,
          color: inStock ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}
