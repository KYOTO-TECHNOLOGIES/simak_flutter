import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/delivery/widgets/delivery_common_widgets.dart';
import 'package:uae_ecom_project/features/delivery/screens/delivery_status_update_screen.dart';

import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final bool isAvailableOrder;

  const DeliveryOrderDetailScreen({
    super.key, 
    required this.order,
    this.isAvailableOrder = false,
  });

  @override
  State<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryController>().fetchOrderDetails(widget.order.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryController = context.watch<DeliveryController>();
    final order = deliveryController.selectedOrder?.id == widget.order.id 
        ? deliveryController.selectedOrder! 
        : widget.order;
    final isLoading = deliveryController.isLoadingOrderDetails;

    final addressPhone = order.shippingAddressDetails?.phoneNumber;
    final profilePhone = order.profileMobileNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('BACK', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading && order.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ─── Header ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.id}',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              'LOGISTICS / ORDER ID',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(order),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ─── Summary Bar ─────────────────────────────────────
                  Row(
                    children: [
                      _buildSummaryItem('CREATED', _formatDate(order.createdAt)),
                      _buildSummaryItem('SETTLEMENT', 'AED ${order.totalPrice.toStringAsFixed(2)}'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── Scheduled Delivery Card ──────────────────────────
                  _buildScheduledDeliveryCard(order),

                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFF1F2F6), thickness: 1),
                  const SizedBox(height: 40),

                  if (order.deliveryCancelRequest != null) ...[
                    _buildCancellationRequestSection(order.deliveryCancelRequest!),
                    const SizedBox(height: 40),
                    const Divider(color: Color(0xFFF1F2F6), thickness: 1),
                    const SizedBox(height: 40),
                  ],

                  // ─── Destination Section ──────────────────────────────
                  Text(
                    'SHIP-TO DESTINATION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    (order.customerName != null && order.customerName!.isNotEmpty 
                        ? order.customerName! 
                        : 'CUSTOMER').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.shippingAddressDetails?.line1 ?? 'No Address'}\n${order.shippingAddressDetails?.state ?? ''}'.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ─── Contact Section ──────────────────────────────────
                  Text(
                    'CONTACT INFORMATION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (addressPhone != null && addressPhone.isNotEmpty)
                    _buildPhoneRow(
                      label: 'ADDRESS PHONE',
                      phone: addressPhone,
                    ),
                  if (profilePhone != null && profilePhone.isNotEmpty) ...[
                    if (addressPhone != null && addressPhone.isNotEmpty)
                      const SizedBox(height: 12),
                    _buildPhoneRow(
                      label: 'MOBILE NUMBER',
                      phone: profilePhone,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (order.deliveryNotes != null) ...[
                    Text(
                      'ENTRY PROTOCOL / NOTES',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.deliveryNotes!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  if (order.status != 'CANCELLED' && 
                      order.deliveryCancelRequest?.status != 'APPROVED' && 
                      order.deliveryCancelRequest?.status != 'REJECTED') ...[
                    Row(
                      // children: [
                      //   Expanded(
                      //     child: _buildActionButton('COPY NUMBER', Icons.copy_outlined, () => _copyToClipboard(context, order.customerPhone)),
                      //   ),
                      // ],
                    ),
                    const SizedBox(height: 2),
                    _buildActionButton(
                      'MAP NAVIGATION',
                      Icons.map_outlined,
                      () => _launchMapWithCoords(
                        latitude: order.shippingAddressDetails?.latitude,
                        longitude: order.shippingAddressDetails?.longitude,
                        fallbackAddress: order.shippingAddressDetails?.line1,
                      ),
                      isFullWidth: true,
                    ),
                  ],

                  const SizedBox(height: 48),

                  // ─── Logistics Chain ─────────────────────────────────
                  Text(
                    'LOGISTICS CHAIN',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLogisticsItem('PHASE', _formatStatus(order.deliveryAssignmentStatus ?? order.status)),
                  const SizedBox(height: 16),
                  _buildLogisticsItem('TIME ASSIGNED', _formatDateTime(order.deliveryAssignedAt ?? order.createdAt)),

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Shipment Manifest ───────────────────────────────
                  Text(
                    'SHIPMENT MANIFEST',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (order.items.isEmpty && isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (order.items.isEmpty)
                    Text('No items in this order', style: GoogleFonts.outfit(color: Colors.grey))
                  else ...[
                    ...order.items.map((item) => _buildManifestItem(item)),
                    if (order.tipAmount > 0)
                      _buildTipManifestItem(order.tipAmount),
                  ],

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Financials ──────────────────────────────────────
                  _buildFinancialRow('ORDER VALUE', order.subTotal > 0 ? order.subTotal : (order.totalPrice - order.tipAmount - order.deliveryCharge)),
                  if (order.deliveryCharge > 0) ...[
                    const SizedBox(height: 12),
                    _buildFinancialRow('DELIVERY CHARGE', order.deliveryCharge),
                  ],
                  if (order.tipAmount > 0) ...[
                    const SizedBox(height: 12),
                    _buildFinancialRow('TIP AMOUNT', order.tipAmount),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'FINAL SETTLEMENT',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D3436),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D3436),
                              ),
                              children: [
                                const TextSpan(text: 'AED '),
                                TextSpan(
                                  text: order.totalPrice.toStringAsFixed(2),
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2D3436),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Settlement Method ───────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SETTLEMENT METHOD',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatPaymentMethod(order.paymentMethod),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D3436),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STATUS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      _formatStatus(order.paymentInfo?.status ?? 'PENDING'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: (order.paymentInfo?.status.toUpperCase() == 'PENDING')
                                            ? const Color(0xFFF39C12)
                                            : (order.paymentInfo?.status.toUpperCase() == 'FAILED')
                                                ? const Color(0xFFD63031)
                                                : const Color(0xFF00B894),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'TRANSACTION ID',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.paymentInfo?.transactionId ?? 'N/A',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3436),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Logistics Intelligence ──────────────────────────
                  Text(
                    'LOGISTICS INTELLIGENCE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildIntelligenceItem(_formatStatus('ASSIGNED'), order.deliveryAssignedAt),
                  const SizedBox(height: 16),
                  _buildIntelligenceItem(_formatStatus('ACCEPTED'), order.deliveryAcceptedAt),
                  if (order.deliveryDeliveredAt != null) ...[
                    const SizedBox(height: 16),
                    _buildIntelligenceItem(_formatStatus('COMPLETED'), order.deliveryDeliveredAt),
                  ],

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Timeline ────────────────────────────────────────
                  Text(
                    'ORDER TIMELINE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTimeline(order.statusHistory),

                  const SizedBox(height: 60),

                  // ─── Footer Buttons ──────────────────────────────────
                  if (widget.isAvailableOrder)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: context.watch<DeliveryController>().isActionLoading 
                          ? null 
                          : () async {
                              final success = await context.read<DeliveryController>().claimOrder(order.id);
                              if (success) {
                                if (!context.mounted) return;
                                Navigator.pop(context); // Go back to available orders
                                // Refresh My Orders so the new order appears
                                final auth = context.read<AuthController>();
                                if (auth.currentUser?.id != null) {
                                  context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                                }
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
                                  ),
                                );
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to claim order: ${context.read<DeliveryController>().error}')),
                                );
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: context.watch<DeliveryController>().isActionLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'CLAIM ORDER',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    )
                  else if (order.status == 'DELIVERED' || 
                      order.status == 'CANCELLED' || 
                      order.deliveryCancelRequest?.status == 'APPROVED' || 
                      order.deliveryCancelRequest?.status == 'REJECTED')
                    const SizedBox.shrink()
                  else if (order.status == 'PROCESSING')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _navigateToUpdateStatusScreen(context, null, order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          'INITIALIZE SHIPMENT',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _navigateToUpdateStatusScreen(context, 'DELIVERED', order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          'ACKNOWLEDGE COMPLETION',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => _showCancellationDialog(context, order),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFEBEB)),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          'ABORT DELIVERY TASK',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: const Color(0xFFD63031),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  if (order.status == 'DELIVERED' && order.receiptImage != null) ...[
                    const SizedBox(height: 48),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HANDOVER AUTHORIZATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Icon(Icons.verified_user_outlined, color: Colors.white.withOpacity(0.4), size: 14),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 280),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomImage(
                                  order.receiptImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RELEASED TO',
                                    style: GoogleFonts.outfit(
                                      fontSize: 7,
                                      color: Colors.white.withOpacity(0.4),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    'AUTHORIZED RECEIVER',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildManifestItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AED ${item.priceAtOrder.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.preparationSpecification != null && item.preparationSpecification!.isNotEmpty 
                            ? 'PREP SPECIFICATION: ${item.preparationSpecification!.toUpperCase()}'
                            : 'PREP SPECIFICATION: NO',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.unit != null && item.unit!.isNotEmpty ? '${item.quantity} ${item.unit}' : 'QTY ${item.quantity}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SUBTOTAL AED ${(item.priceAtOrder * item.quantity).toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipManifestItem(double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TIP FOR DELIVERY PARTNER',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
         
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AED ${amount.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3436),
              ),
              children: [
                const TextSpan(text: 'AED '),
                TextSpan(
                  text: amount.toStringAsFixed(2),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(OrderModel order) {
    String status = order.status;
    Color statusColor = Colors.grey;
    bool isPendingCancel = order.deliveryCancelRequest != null && order.deliveryCancelRequest!.status == 'PENDING';

    if (isPendingCancel) {
      status = 'CANCELLATION PENDING';
      statusColor = const Color(0xFFE17055); // Orange-ish
    } else {
      switch (status.toUpperCase()) {
        case 'PROCESSING': statusColor = const Color(0xFFF39C12); break;
        case 'SHIPPED': statusColor = const Color(0xFF6C5CE7); break;
        case 'DELIVERED': statusColor = const Color(0xFF00B894); break;
        case 'CANCELLED': statusColor = const Color(0xFFD63031); break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _formatStatus(status),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancellationRequestSection(DeliveryCancelRequest request) {
    Color statusColor = const Color(0xFFF39C12);
    IconData statusIcon = Icons.pending_actions_outlined;
    String statusText = 'CANCELLATION REQUEST UNDER REVIEW';

    if (request.status == 'APPROVED') {
      statusColor = const Color(0xFF00B894);
      statusIcon = Icons.check_circle_outline;
      statusText = 'CANCELLATION APPROVED';
    } else if (request.status == 'REJECTED') {
      statusColor = const Color(0xFFD63031);
      statusIcon = Icons.cancel_outlined;
      statusText = 'CANCELLATION REJECTED';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'DELIVERY CANCELLATION REQUEST',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'REASON',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.reason,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF636E72),
            ),
          ),
          if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'ADMIN FEEDBACK',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.reviewNotes!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3436),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Requested on ${_formatDateTime(request.requestedAt)}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Reviewed on ${_formatDateTime(request.reviewedAt!)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledDeliveryCard(OrderModel order) {
    final slotDetails = order.preferredDeliverySlotDetails;
    final startTime = slotDetails?['start_time_display']?.toString();
    final endTime = slotDetails?['end_time_display']?.toString();

    final dateStr = _formatDateString(order.preferredDeliveryDate);
    final String? timeRange = (startTime != null &&
            startTime.isNotEmpty &&
            endTime != null &&
            endTime.isNotEmpty)
        ? '$startTime – $endTime'
        : (order.preferredDeliverySlotName != null &&
                order.preferredDeliverySlotName!.isNotEmpty
            ? order.preferredDeliverySlotName
            : null);

    if (order.preferredDeliveryDate == null && timeRange == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Calendar icon box ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFECEFF1)),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(width: 16),
          // ── Date + time range ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHEDULED DELIVERY',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                if (timeRange != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D3436),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text(
                      timeRange,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isFullWidth = false}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFF1F2F6)),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<StatusHistoryItem> history) {
    if (history.isEmpty) {
      return Text('No history available', style: GoogleFonts.outfit(color: Colors.grey));
    }

    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        color: Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatStatus(item.status),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${item.notes}"',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
  }

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    return '${_formatDate(localDate)}, ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}:${localDate.second.toString().padLeft(2, '0')}';
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return _formatDate(date);
    } catch (_) {
      return dateStr;
    }
  }


  String _formatStatus(String status) {
    if (status.isEmpty) return 'N/A';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  /// Maps raw backend gateway/payment-method values to user-friendly labels.
  String _formatPaymentMethod(String method) {
    if (method.isEmpty) return 'Card';
    final m = method.toUpperCase().trim();
    if (m == 'COD' || m.contains('CASH')) return 'Cash on Delivery';
    if (m == 'ZIINA' ||
        m == 'TELR' ||
        m.contains('ONLINE') ||
        m.contains('CARD') ||
        m.contains('PAY')) {
      return 'Card';
    }
    // Fallback: title-case the raw value
    return method
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }


  Future<void> _launchMapWithCoords({
    double? latitude,
    double? longitude,
    String? fallbackAddress,
  }) async {
    Uri uri;

    if (latitude != null && longitude != null) {
      // Use exact coordinates — pinpoints the precise location
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else if (fallbackAddress != null && fallbackAddress.isNotEmpty) {
      // Fall back to address text search if no coordinates available
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fallbackAddress)}',
      );
    } else {
      return; // Nothing to navigate to
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToUpdateStatusScreen(BuildContext context, String? status, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryStatusUpdateScreen(
          order: order,
          initialStatus: status,
        ),
      ),
    );
  }

  void _showCancellationDialog(BuildContext context, OrderModel order) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final controller = context.watch<DeliveryController>();
          final bool isReasonProvided = reasonController.text.trim().isNotEmpty;
          final bool isLoading = controller.isActionLoading;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Cancellation',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Briefly explain why this delivery cannot be completed.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reasonController,
                    onChanged: (_) => setDialogState(() {}),
                    maxLines: 4,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g., Customer unreachable or incorrect address',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (!isReasonProvided || isLoading)
                          ? null
                          : () async {
                              final success = await context.read<DeliveryController>().updateStatus(
                                order.id,
                                'CANCELLED',
                                cancelReason: reasonController.text.trim(),
                              );
                              
                              if (!context.mounted) return;
                              
                              if (success) {
                                Navigator.pop(context);
                                // Refresh My Orders tab
                                final auth = context.read<AuthController>();
                                if (auth.currentUser?.id != null) {
                                  context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cancellation request submitted')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${controller.error}')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReasonProvided ? const Color(0xFFD63031) : const Color(0xFFFFB2B2),
                        disabledBackgroundColor: const Color(0xFFFFE8E8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'SUBMIT REQUEST',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Text(
                        'GO BACK',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade400,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneRow({required String label, required String phone}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F2F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.phone_outlined, color: Colors.grey.shade400, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF00B894),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.call, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceItem(String label, DateTime? dateTime) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        Text(
          dateTime != null ? _formatDateTime(dateTime) : 'N/A',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }
}
