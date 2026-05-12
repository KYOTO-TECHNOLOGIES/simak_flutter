import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/core/widgets/prep_selection_sheet.dart';
import 'package:uae_ecom_project/core/utils/feedback_utils.dart';

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
                  Navigator.pushNamed(
                    context,
                    '/login',
                  );
                }
                return;
              }

              // MANDATORY: Preparation specification check
              if (product.preparationSpecifications.isNotEmpty) {
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PrepSelectionSheet(
                      product: product,
                      onSelected: (specId, instructions) async {
                        final success = await cart.addToCart(
                          product.id,
                          1,
                          preparationSpecificationId: specId,
                          preparationInstructions: instructions,
                        );

                        if (success) {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                          if (context.mounted) {
                            SimakFeedback.showSuccess(
                              context,
                              trStatic(context, 'added_to_cart'),
                            );
                            // Optional: Navigate to cart if desired, matching "Buy Now"
                            // Navigator.pushNamed(context, '/cart');
                          }
                        } else {
                          if (context.mounted) {
                            SimakFeedback.showError(
                              context,
                              cart.error ?? trStatic(context, 'failed_add_cart'),
                            );
                          }
                        }
                      },
                    ),
                  );
                }
                return;
              }

              // Always try to add to cart (increments quantity if already exists)
              final success = await cart.addToCart(product.id, 1);

              if (context.mounted) {
                if (success) {
                  SimakFeedback.showSuccess(
                    context,
                    trStatic(context, 'added_to_cart'),
                  );
                } else {
                  SimakFeedback.showError(
                    context,
                    cart.error ?? trStatic(context, 'failed_add_cart'),
                  );
                }
              }
            }
          : () async {
              final auth = context.read<AuthController>();
              if (!auth.isLoggedIn) {
                if (context.mounted) {
                  Navigator.pushNamed(
                    context,
                    '/login',
                  );
                }
                return;
              }

              final controller = context.read<ProductController>();
              final success = await controller.notifyMe(product.id);

              if (context.mounted) {
                if (success) {
                  SimakFeedback.showSuccess(
                    context,
                    trStatic(context, 'notify_all_set'),
                  );
                } else {
                  SimakFeedback.showError(
                    context,
                    trStatic(context, 'notify_failed'),
                  );
                }
              }
            },
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
          inStock
              ? Icons.shopping_cart_rounded
              : Icons.notifications_active_outlined,
          size: iconSize,
          color: inStock ? AppColors.primary : AppColors.actionBlue,
        ),
      ),
    );
  }
}
