import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/delivery/screens/delivery_order_detail_screen.dart';
import 'package:uae_ecom_project/features/delivery/widgets/delivery_common_widgets.dart';
import 'package:uae_ecom_project/features/delivery/widgets/status_update_sheet.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  int _selectedFilter = 0;
  final List<String> _filters = ['ALL ORDERS', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final auth = context.read<AuthController>();
      if (auth.currentUser?.id != null) {
        context.read<OrderController>().loadMoreOrders(userId: auth.currentUser!.id!);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthController>();
    if (auth.currentUser?.id != null) {
      await context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final allOrders = orderController.orders;

    final filteredOrders = allOrders.where((o) {
      if (_selectedFilter == 0) return true; // ALL ORDERS
      final filterStatus = _filters[_selectedFilter];
      final status = o.status.toUpperCase();
      
      if (filterStatus == 'PROCESSING') {
        // Broaden the filter: If it's not finished/shipped/cancelled, it's processing for the rider
        return status != 'SHIPPED' && 
               status != 'DELIVERED' && 
               status != 'CANCELLED' && 
               status != 'COMPLETED' &&
               status != 'RETURNED';
      }
      return status == filterStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header & Search ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Deliveries',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track your active and past orders',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Filters Row ──────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = index);
                  },
                  selectedColor: const Color(0xFF2D3436),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2D3436) : const Color(0xFFF1F2F6),
                    ),
                  ),
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // ─── Orders List ──────────────────────────────────────────
        Expanded(
          child: orderController.error != null
            ? _buildErrorState(orderController.error!)
            : (filteredOrders.isEmpty && !orderController.isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredOrders.length + (orderController.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredOrders.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final order = filteredOrders[index];
                    return MyOrderCard(order: order);
                  },
                )),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade200),
              const SizedBox(height: 16),
              Text(
                'No orders found',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF7675)),
                const SizedBox(height: 16),
                Text(
                  'Failed to load orders',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MyOrderCard extends StatelessWidget {
  final OrderModel order;

  const MyOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      if (order.deliveryCancelRequest != null && order.deliveryCancelRequest!.status == 'PENDING') {
        return const Color(0xFFFD8D3C); // Vibrant orange for pending cancel
      }
      switch (order.status.toUpperCase()) {
        case 'PROCESSING':
        case 'PAID':
        case 'ASSIGNED':
        case 'ACCEPTED':
        case 'READY':
          return const Color(0xFFF39C12);
        case 'SHIPPED':
          return const Color(0xFF6C5CE7);
        case 'DELIVERED':
          return const Color(0xFF00B894);
        case 'CANCELLED':
          return const Color(0xFFD63031);
        default:
          return Colors.grey;
      }
    }

    final statusColor = getStatusColor();
    final statusBg = statusColor.withOpacity(0.08);

    // Date formatting
    String displayDate = '';
    if (order.preferredDeliveryDate != null) {
      try {
        final date = DateTime.parse(order.preferredDeliveryDate!);
        displayDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        displayDate = order.preferredDeliveryDate!;
      }
    } else {
      displayDate = '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryOrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F2F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header & Status ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.id}',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      Text(
                        'DUE: $displayDate${order.preferredDeliverySlotName != null ? ' - ${order.preferredDeliverySlotName!.toUpperCase()}' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Text(
                          _formatStatus(order.status),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (order.deliveryCancelRequest != null && order.deliveryCancelRequest!.status == 'PENDING') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CANCEL PENDING',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFD8D3C),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ─── Address ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.shippingAddressDetails?.line1 ?? 'No Address'}, ${order.shippingAddressDetails?.state ?? ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Customer ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Customer',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Price & Tip ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2D3436),
                      ),
                      children: [
                        TextSpan(text: 'AED ${order.totalPrice.toStringAsFixed(2)}'),
                        if (order.tipAmount > 0) ...[
                          TextSpan(
                            text: '\n+ AED ${order.tipAmount.toStringAsFixed(2)} TIP',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00B894),
                            ),
                          ),
                        ],
                      ],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: DashedDivider(color: Color(0xFFF1F2F6)),
            ),

            // ─── Footer Action ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ASSIGNED',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF39C12),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (order.status.toUpperCase() != 'DELIVERED' && 
                          order.status.toUpperCase() != 'CANCELLED' && 
                          order.deliveryCancelRequest?.status != 'PENDING')
                        TextButton(
                          onPressed: () => _showUpdateStatusSheet(context, order),
                          child: Text(
                            'UPDATE STATUS',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.actionBlue,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF1F2F6)),
                        ),
                        child: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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


  void _showUpdateStatusSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusUpdateSheet(order: order),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'N/A';
    return status.replaceAll('_', ' ').toUpperCase();
  }
}


