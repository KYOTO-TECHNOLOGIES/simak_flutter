import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/delivery/screens/delivery_order_detail_screen.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';

class AvailableOrdersView extends StatefulWidget {
  const AvailableOrdersView({super.key});

  @override
  State<AvailableOrdersView> createState() => _AvailableOrdersViewState();
}

class _AvailableOrdersViewState extends State<AvailableOrdersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryController>().fetchAvailableOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryController = context.watch<DeliveryController>();

    return deliveryController.isLoadingAvailableOrders 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Section ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Orders',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick up new deliveries in your assigned region',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F2F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.read<DeliveryController>().fetchAvailableOrders(),
                      icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Available Orders Grid ─────────────────────────────
              if (deliveryController.availableOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text(
                          'No orders available in your region',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                    double childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.25;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: deliveryController.availableOrders.length,
                      itemBuilder: (context, index) {
                        final order = deliveryController.availableOrders[index];
                        return AvailableOrderCard(
                          order: order,
                          isHighlighted: index == 0,
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
  }
}

class AvailableOrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isHighlighted;

  const AvailableOrderCard({
    super.key,
    required this.order,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryOrderDetailScreen(
              order: order,
              isAvailableOrder: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlighted ? AppColors.actionBlue.withOpacity(0.3) : const Color(0xFFF1F2F6),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: AppColors.actionBlue.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Icon Placeholder top-right
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted ? const Color(0xFFF1FBFF) : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: isHighlighted ? AppColors.actionBlue : Colors.grey.shade400,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id}',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  Text(
                    'POSTED ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName ?? order.shippingAddressDetails?.name ?? 'Customer',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              '${order.shippingAddressDetails?.addressLine1 ?? ''}, ${order.shippingAddressDetails?.state ?? ''}'.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007AFF), AppColors.actionBlue],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.actionBlue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: controller.isActionLoading ? null : () async {
                                final success = await context.read<DeliveryController>().claimOrder(order.id);
                                  if (success) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Order Claimed Successfully',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                        backgroundColor: const Color(0xFF00B894),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  
                                  // Refresh My Orders
                                  final auth = context.read<AuthController>();
                                  if (auth.currentUser?.id != null) {
                                    context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                                  }
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to claim order: ${context.read<DeliveryController>().error}')),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (controller.isActionLoading)
                                    const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  else ...[
                                    Text(
                                      'CLAIM',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                                  ],
                                ],
                              ),
                            ),
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
}
