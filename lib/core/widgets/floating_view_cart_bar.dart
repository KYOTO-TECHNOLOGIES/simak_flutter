import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';

class FloatingViewCartBar extends StatelessWidget {
  final bool isVisible;
  const FloatingViewCartBar({super.key, this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, controller, child) {
        final cart = controller.cart;
        final hasItems = isVisible && cart != null && cart.items.isNotEmpty;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: !hasItems
              ? const SizedBox.shrink()
              : Center(
                  child: GestureDetector(
                    key: const ValueKey('floating_cart_bar'),
                    onTap: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: Container(
                      width: 180, // Fixed width for a more compact pill look
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Product Thumbnail
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipOval(
                              child: CustomImage(
                                cart.items.last.product.mainImage ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // View Cart Text
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(context, 'view_cart').replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${cart.items.length} ${cart.items.length == 1 ? tr(context, 'item') : tr(context, 'items_count')}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Arrow Icon
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
