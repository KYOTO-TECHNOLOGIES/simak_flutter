import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/screens/login_screen.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/core/utils/feedback_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartController>().fetchCart();
      context.read<OrderController>().fetchDeliverySettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartController = context.watch<CartController>();
    final authController = context.watch<AuthController>();
    final isLoggedIn = authController.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '${tr(context, 'my_cart')} (${cartController.uniqueItemCount})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr(context, 'continue_shopping'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !isLoggedIn
          ? _buildGuestState(context, theme)
          : cartController.error != null && cartController.cart == null
          ? _buildErrorState(context, theme, cartController.error!)
          : cartController.isLoading && cartController.cart == null
          ? const Center(child: CircularProgressIndicator())
          : cartController.uniqueItemCount == 0
          ? _buildEmptyState(context, theme)
          : _buildCartBody(context, theme, cartController),
    );
  }

  Future<void> _handleProceedToCheckout(
    BuildContext context,
    CartController controller,
  ) async {
    if (controller.hasOutOfStock) {
      final shouldContinue = await _showOutOfStockItemsDialog(context, controller);
      if (shouldContinue != true) return;
      await controller.removeOutOfStockItems();
      if (!context.mounted || !controller.hasInStockItems) return;
    }

    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      '/order',
      arguments: {'isCartMode': true},
    );
  }

  Future<bool?> _showOutOfStockItemsDialog(
    BuildContext context,
    CartController controller,
  ) {
    final unavailableItems = controller.outOfStockItems;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'Few items are unavailable for checkout',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: unavailableItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, index) =>
                          _buildUnavailableItemTile(unavailableItems[index]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Text(
                    'Please continue with other available items.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(dialogContext, false),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(dialogContext, true),
                          child: Center(
                            child: Text(
                              'Yes, Continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnavailableItemTile(CartItemModel item) {
    final details = item.preparationSpecificationName != null &&
            item.preparationSpecificationName!.trim().isNotEmpty
        ? item.preparationSpecificationName!.trim()
        : '${item.quantity} ${item.product.unit.replaceAll('_', ' ')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CustomImage(
            item.product.thumbnail,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            padding: const EdgeInsets.all(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                details,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Out Of Stock',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartBody(
    BuildContext context,
    ThemeData theme,
    CartController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.fetchCart,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // List of Items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = controller.cart!.items[index];
                return _buildCartItem(context, theme, item, controller);
              }, childCount: controller.cart!.items.length),
            ),
          ),

          // Order Summary Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: _buildOrderSummary(context, theme, controller),
            ),
          ),

          // Bottom Safe Area Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    ThemeData theme,
    CartItemModel item,
    CartController controller,
  ) {
    return Dismissible(
      key: Key('cart_item_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        final success = await controller.removeItem(
          item.product.id,
          preparationSpecificationId: item.preparationSpecificationId,
          cartItemId: item.id,
        );
        if (!success && context.mounted) {
          SimakFeedback.showError(
            context,
            controller.error ?? trStatic(context, 'failed_to_remove'),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImage(
                item.product.thumbnail,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                padding: const EdgeInsets.all(8.0),
              ),
            ),
            const SizedBox(width: 16),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      controller.isItemRemoving(item.product.id,
                              preparationId: item.preparationSpecificationId,
                              cartItemId: item.id)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.error),
                              ),
                            )
                          : IconButton(
                              onPressed: () async {
                                final success = await controller.removeItem(
                                  item.product.id,
                                  preparationSpecificationId:
                                      item.preparationSpecificationId,
                                  cartItemId: item.id,
                                );
                                if (!success && context.mounted) {
                                  SimakFeedback.showError(
                                    context,
                                    controller.error ?? trStatic(context, 'failed_to_remove'),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.grey,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                    ],
                  ),

                  Text(
                    '${item.quantity.toInt()} ${item.product.unit.replaceAll('_', ' ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  // Preparation Badge
                  if (item.preparationSpecificationName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Prep: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            item.preparationSpecificationName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Stock Status Badge
                  if (item.product.stock == 0 || !item.product.isAvailable)
                    _buildStatusBadge(trStatic(context, 'out_of_stock'), AppColors.error)
                  else if (item.quantity > item.product.stock)
                    _buildStatusBadge(
                      trStatic(context, 'insufficient_stock', args: {'count': item.product.stock.toString()}),
                      AppColors.error,
                    )
                  else if (item.product.stock <= 5)
                    _buildStatusBadge(trStatic(context, 'only_few_left'), Colors.orange),

                  const SizedBox(height: 12),

                  // Quantity Selector and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuantitySelector(item, controller),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AED ${item.subtotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(CartItemModel item, CartController controller) {
    final isUpdating = controller.isItemUpdatingQuantity(item.product.id,
        preparationId: item.preparationSpecificationId,
        cartItemId: item.id);
    final displayQuantity = controller.getItemQuantity(item);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniBtn(
            icon: Icons.remove,
            onTap: () => controller.updateQuantity(item.product.id,
                displayQuantity - 1,
                preparationSpecificationId: item.preparationSpecificationId,
                cartItemId: item.id),
            isDisabled: displayQuantity <= 1 || isUpdating,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: isUpdating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${displayQuantity}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
          _buildMiniBtn(
            icon: Icons.add,
            onTap: () {
              if (displayQuantity >= item.product.stock) {
                SimakFeedback.showInfo(
                  context,
                  "That's our full catch! Only ${item.product.stock} fresh from Simak.",
                );
                return;
              }
              controller.updateQuantity(item.product.id, displayQuantity + 1,
                  preparationSpecificationId: item.preparationSpecificationId,
                  cartItemId: item.id);
            },
            isDisabled: item.product.stock == 0 ||
                !item.product.isAvailable ||
                isUpdating,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isDisabled ? Colors.grey.shade100 : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    ThemeData theme,
    CartController controller,
  ) {
    final orderController = context.watch<OrderController>();
    final threshold = orderController.freeDeliveryThreshold;
    
    // Use in-stock total if there are OOS items
    final subtotal = controller.hasOutOfStock
        ? controller.inStockTotalPrice
        : controller.cart!.totalPrice;

    final isFreeShipping = subtotal >= threshold;
    final shippingCharge = isFreeShipping ? 0.0 : orderController.deliveryCharge;
    final itemsTotal = subtotal + shippingCharge;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'order_summary'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSummaryRow(
            tr(context, 'subtotal'),
            'AED ${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          
          _buildSummaryRow(
            tr(context, 'shipping'),
            isFreeShipping ? 'Free' : 'AED ${shippingCharge.toStringAsFixed(2)}',
            valueColor: isFreeShipping ? AppColors.primary : Colors.black87,
          ),
          const SizedBox(height: 6),
          Text(
            'Delivery is free for orders AED ${threshold.toInt()} above.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1, color: Colors.black12),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'AED ${itemsTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isCartValid
                  ? () async {
                      await _handleProceedToCheckout(context, controller);
                    }
                  : () {
                      if (controller.cart == null ||
                          controller.cart!.items.isEmpty)
                        return;

                      String msg = trStatic(context, 'adjust_to_checkout');
                      if (!controller.hasInStockItems) {
                        msg = trStatic(
                          context,
                          'no_items_available',
                        ); // Custom message for all OOS
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isCartValid
                    ? AppColors.primary
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr(context, 'proceed_to_checkout'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                tr(context, 'secure_checkout'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 120,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'cart_empty'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              tr(context, 'sign_in_to_shop'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                tr(context, 'sign_in_link'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            tr(context, error),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.read<CartController>().fetchCart(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
