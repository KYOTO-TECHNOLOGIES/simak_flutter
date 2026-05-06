import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/delivery/widgets/delivery_common_widgets.dart';
import 'package:uae_ecom_project/features/delivery/widgets/status_update_sheet.dart';

import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const DeliveryOrderDetailScreen({super.key, required this.order});

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BACK',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
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
                      Column(
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
                      _buildStatusBadge(order.status),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ─── Summary Bar ─────────────────────────────────────
                  Row(
                    children: [
                      _buildSummaryItem('CREATED', _formatDate(order.createdAt)),
                      _buildSummaryItem('SETTLEMENT', 'AED ${order.totalPrice.toStringAsFixed(2)}'),
                      _buildSummaryItem('SCHEDULED WINDOW', 
                        '${_formatDateString(order.preferredDeliveryDate)}${order.preferredDeliverySlotName != null && order.preferredDeliverySlotName!.isNotEmpty ? " - ${order.preferredDeliverySlotName}" : ""}'),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFF1F2F6), thickness: 1),
                  const SizedBox(height: 40),

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

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton('CALL CUSTOMER', Icons.phone_outlined, () => _launchCaller(order.customerPhone)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton('COPY NUMBER', Icons.copy_outlined, () => _copyToClipboard(context, order.customerPhone)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton('MAP NAVIGATION', Icons.map_outlined, () => _launchMap(order.shippingAddressDetails?.line1), isFullWidth: true),

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
                  _buildLogisticsItem('PHASE', (order.deliveryAssignmentStatus ?? order.status).toUpperCase()),
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
                  else
                    ...order.items.map((item) => _buildManifestItem(item)),

                  const SizedBox(height: 48),
                  const DashedDivider(),
                  const SizedBox(height: 48),

                  // ─── Financials ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'ORDER VALUE',
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
                                text: order.totalPrice.toStringAsFixed(2),
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
                  ),
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
                                    order.paymentMethod.toUpperCase(),
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
                                      (order.paymentInfo?.status ?? 'SUCCESS').toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF00B894),
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
                  _buildIntelligenceItem('ASSIGNED', order.deliveryAssignedAt),
                  const SizedBox(height: 16),
                  _buildIntelligenceItem('ACCEPTED', order.deliveryAcceptedAt),

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
                  if (order.status == 'DELIVERED')
                    const SizedBox.shrink()
                  else if (order.status == 'PROCESSING')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(
                          context, 
                          'SHIPPED', 
                          'Mark Order #${order.id} as Shipped?',
                          order
                        ),
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
                        onPressed: () => _showUpdateStatusSheet(context, 'DELIVERED', order),
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
                                child: Image.network(
                                  order.receiptImage!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.broken_image, color: Colors.white, size: 48),
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
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'QTY ${item.quantity}',
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

  Widget _buildStatusBadge(String status) {
    Color statusColor = Colors.grey;
    switch (status.toUpperCase()) {
      case 'PROCESSING': statusColor = const Color(0xFFF39C12); break;
      case 'SHIPPED': statusColor = const Color(0xFF6C5CE7); break;
      case 'DELIVERED': statusColor = const Color(0xFF00B894); break;
      case 'CANCELLED': statusColor = const Color(0xFFD63031); break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: statusColor,
          letterSpacing: 1.0,
        ),
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
                        item.status.toUpperCase(),
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

  Future<void> _launchCaller(String? phone) async {
    if (phone == null) return;
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _copyToClipboard(BuildContext context, String? text) {
    if (text == null) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _launchMap(String? address) async {
    if (address == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showUpdateStatusSheet(BuildContext context, String status, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusUpdateSheet(order: order, initialStatus: status),
    );
  }

  void _showConfirmationDialog(BuildContext context, String status, String message, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wait a moment',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showUpdateStatusSheet(context, status, order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1B2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'PROCEED',
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
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Text(
                    'NOT NOW',
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
      ),
    );
  }

  void _showCancellationDialog(BuildContext context, OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  onPressed: () async {
                    if (reasonController.text.isEmpty) return;
                    Navigator.pop(context);
                    final success = await context.read<DeliveryController>().updateStatus(
                      order.id,
                      'CANCELLED',
                      cancelReason: reasonController.text,
                    );
                    if (success) {
                       // Refresh My Orders tab
                       final auth = context.read<AuthController>();
                       if (auth.currentUser?.id != null) {
                         context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                       }
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Cancellation request submitted')),
                       );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB2B2), // Pinkish color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
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
                  onPressed: () => Navigator.pop(context),
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
