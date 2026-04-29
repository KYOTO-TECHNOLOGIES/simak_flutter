import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
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
      if (_selectedFilter == 0) return true; // All
      if (_selectedFilter == 1) { // Active
        return o.status == 'PAID' || o.status == 'PROCESSING' || o.status == 'SHIPPED';
      }
      if (_selectedFilter == 2) return o.status == 'DELIVERED'; // Completed
      if (_selectedFilter == 3) return o.status == 'CANCELLED'; // Cancelled
      return true;
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
                  if (orderController.isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track your assigned orders',
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
                  selectedColor: AppColors.actionBlue.withOpacity(0.1),
                  backgroundColor: const Color(0xFFFAFAFA),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.actionBlue : Colors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isSelected ? AppColors.actionBlue.withOpacity(0.2) : const Color(0xFFF1F2F6),
                    ),
                  ),
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
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: filteredOrders.isEmpty && !orderController.isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return MyOrderCard(order: order);
                  },
                ),
          ),
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
      switch (order.status) {
        case 'PAID': return const Color(0xFF2ecc71);
        case 'PROCESSING': return const Color(0xFFf39c12);
        case 'SHIPPED': return const Color(0xFF9b59b6);
        case 'DELIVERED': return const Color(0xFF3498db);
        case 'CANCELLED': return Colors.red;
        default: return Colors.grey;
      }
    }

    final statusColor = getStatusColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Section ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '#${order.id}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.createdAt.day} ${_getMonth(order.createdAt.month)} ${order.createdAt.year}'.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    order.status,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Address Section ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${order.shippingAddressDetails?.line1 ?? ''}, ${order.shippingAddressDetails?.state ?? ''}'.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436).withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: DashedDivider(),
          ),

          // ─── Items & Amount Section ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${order.items.length} ITEMS',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D3436).withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AED ${order.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: DashedDivider(),
          ),

          // ─── Footer Section ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.status != 'DELIVERED' && order.status != 'CANCELLED')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showUpdateStatusSheet(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'UPDATE STATUS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'DELIVERY COMPLETED',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade300,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Navigate to order detail
                    },
                    icon: const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  void _showUpdateStatusSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusUpdateSheet(order: order),
    );
  }
}

class StatusUpdateSheet extends StatefulWidget {
  final OrderModel order;
  const StatusUpdateSheet({super.key, required this.order});

  @override
  State<StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<StatusUpdateSheet> {
  String? _selectedStatus;
  File? _proofImage;
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    final currentStatus = widget.order.status;

    List<String> availableTransitions = [];
    if (currentStatus == 'PAID' || currentStatus == 'PROCESSING') {
      availableTransitions = ['SHIPPED', 'CANCELLED'];
    } else if (currentStatus == 'SHIPPED') {
      availableTransitions = ['DELIVERED', 'CANCELLED'];
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Update Order Status',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the next status for order #${widget.order.id}',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 12,
            children: availableTransitions.map((status) {
              final isSelected = _selectedStatus == status;
              return ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedStatus = selected ? status : null);
                },
                selectedColor: AppColors.actionBlue.withOpacity(0.1),
                labelStyle: GoogleFonts.outfit(
                  color: isSelected ? AppColors.actionBlue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),

          if (_selectedStatus == 'DELIVERED') ...[
            const SizedBox(height: 24),
            Text(
              'Delivery Proof (Required)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) setState(() => _proofImage = File(image.path));
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_proofImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Take Photo', style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
          ],

          if (_selectedStatus == 'CANCELLED') ...[
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'e.g. Customer unreachable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Internal Notes',
              hintText: 'Optional notes for this update',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_selectedStatus == null || 
                         (controller.isActionLoading) ||
                         (_selectedStatus == 'DELIVERED' && _proofImage == null) ||
                         (_selectedStatus == 'CANCELLED' && _reasonController.text.isEmpty))
                  ? null
                  : () async {
                      final success = await context.read<DeliveryController>().updateStatus(
                        widget.order.id,
                        _selectedStatus!,
                        proofImage: _proofImage,
                        cancelReason: _reasonController.text,
                        notes: _notesController.text,
                      );

                      if (!mounted) return;
                      
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_selectedStatus == 'CANCELLED' 
                            ? 'Cancellation request submitted' 
                            : 'Status updated successfully!')),
                        );
                        // Refresh orders
                        final auth = context.read<AuthController>();
                        if (auth.currentUser?.id != null) {
                          context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                        }
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${controller.error}')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isActionLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _selectedStatus == 'CANCELLED' ? 'REQUEST CANCELLATION' : 'CONFIRM UPDATE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DashedDivider({super.key, this.height = 1, this.color = const Color(0xFFF1F2F6)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 3.0; // Reduced dash width for a more polished look
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
