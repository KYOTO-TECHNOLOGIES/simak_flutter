import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';
import 'package:uae_ecom_project/features/payment/screens/payment_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = false;
  String? _resolvedSlotLabel;
  String? _resolvedSlotRange;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    if (_order == null) {
      _fetchDetails();
    } else {
      _resolveSlotNames(_order!);
    }
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final controller = context.read<OrderController>();
      final data = await controller.fetchOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _isLoading = false;
        });
        if (data != null) {
          _resolveSlotNames(data);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resolveSlotNames(OrderModel order) async {
    final slot = order.preferredDeliverySlot;
    if (slot == null || slot.isEmpty) return;

    if (slot.contains('(')) {
      setState(() {
        _resolvedSlotRange = slot.substring(0, slot.indexOf('(')).trim();
        _resolvedSlotLabel = slot
            .substring(slot.indexOf('('))
            .replaceAll('(', '')
            .replaceAll(')', '')
            .trim();
      });
      return;
    }

    final date = order.preferredDeliveryDate;
    if (date == null || date.isEmpty) {
      setState(() {
        _resolvedSlotRange = slot;
        _resolvedSlotLabel = '';
      });
      return;
    }

    try {
      final response = await OrderService().getAvailableSlots(date);
      if (response.containsKey('available_slots')) {
        final List<dynamic> slotsJson = response['available_slots'];
        final List<String> ids = slot.split(',').map((e) => e.trim()).toList();

        List<String> labels = [];
        List<String> ranges = [];

        for (var idStr in ids) {
          final id = int.tryParse(idStr);
          if (id != null) {
            final match = slotsJson.firstWhere(
              (s) => s['id'] == id,
              orElse: () => null,
            );
            if (match != null) {
              if (match['name'] != null && !labels.contains(match['name']))
                labels.add(match['name']);
              final range =
                  '${match['start_time_display']} - ${match['end_time_display']}';
              if (!ranges.contains(range)) ranges.add(range);
            }
          }
        }

        if (labels.isNotEmpty || ranges.isNotEmpty) {
          setState(() {
            _resolvedSlotLabel = labels.join(', ');
            _resolvedSlotRange = ranges.join(', ');
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error resolving slot names: $e');
    }

    setState(() {
      _resolvedSlotRange = slot;
      _resolvedSlotLabel = '';
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hr = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hr:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          tr(context, 'order_details'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.actionBlue),
            )
          : _order == null
          ? const Center(child: Text('Order not found'))
          : _buildContent(context, _order!, theme, isDark),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: _fetchDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, order, theme, isDark),
            const SizedBox(height: 16),
            _buildOrderedItems(context, order, theme, isDark),
            const SizedBox(height: 16),
            _buildTimeline(context, order, theme, isDark),
            const SizedBox(height: 16),
            _buildDeliveryAddress(context, order, theme, isDark),
            const SizedBox(height: 16),
            _buildPaymentInfo(context, order, theme, isDark),
            const SizedBox(height: 16),
            _buildSummary(context, order, theme, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(order.status),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ORDER TOTAL'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    Text(
                      'AED ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.actionBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Order #${order.id}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Placed ${_formatDate(order.createdAt)}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.green;
      case 'PAID':
        return Colors.orange;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    IconData icon;
    switch (status.toUpperCase()) {
      case 'PENDING':
        icon = Icons.access_time;
        break;
      case 'PAID':
        icon = Icons.payments_outlined;
        break;
      case 'PROCESSING':
        icon = Icons.sync;
        break;
      case 'SHIPPED':
        icon = Icons.local_shipping;
        break;
      case 'DELIVERED':
        icon = Icons.check_circle;
        break;
      case 'CANCELLED':
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedItems(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppColors.actionBlue,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Ordered Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${order.items.length} Items',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...order.items
              .map(
                (item) =>
                    _buildItemRow(context, item, order.status, theme, isDark),
              )
              .toList(),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, OrderItem item) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    final List<File> selectedImages = [];
    bool isSubmitting = false;

    const ratingLabels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.product.thumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WRITE YOUR REVIEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trText(context, item.product.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedRating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              starIndex <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: starIndex <= selectedRating
                                  ? const Color(0xFFFFB800)
                                  : Colors.grey[350],
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        ratingLabels[selectedRating],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ADD PHOTOS (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...selectedImages.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  entry.value,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedImages.removeAt(entry.key);
                                    });
                                  },
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final images = await picker.pickMultiImage(
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 80,
                            );
                            if (images.isNotEmpty) {
                              setDialogState(() {
                                selectedImages.addAll(
                                  images.map((x) => File(x.path)),
                                );
                              });
                            }
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.actionBlue.withOpacity(0.3),
                                width: 1.5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 22,
                                  color: AppColors.actionBlue.withOpacity(0.6),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.actionBlue.withOpacity(
                                      0.6,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedRating == 0 || isSubmitting
                            ? null
                            : () async {
                                setDialogState(() => isSubmitting = true);
                                final controller = context
                                    .read<OrderController>();
                                final success = await controller.addReview(
                                  productId: item.product.id,
                                  rating: selectedRating,
                                  comment: commentController.text.trim(),
                                  images: selectedImages,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: success
                                          ? AppColors.actionBlue
                                          : Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Row(
                                        children: [
                                          Icon(
                                            success
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            success
                                                ? 'Review submitted successfully!'
                                                : 'Failed to submit review',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    OrderItem item,
    String orderStatus,
    ThemeData theme,
    bool isDark,
  ) {
    final canReview = orderStatus.toUpperCase() == 'DELIVERED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.03)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.product.thumbnail,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: Colors.grey[100],
                child: const Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trText(context, item.product.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.actionBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.actionBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'AED ${item.priceAtOrder.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (canReview) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showReviewDialog(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.actionBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 13,
                            color: AppColors.actionBlue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tr(context, 'order_write_review'),
                              style: const TextStyle(
                                color: AppColors.actionBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AED ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: AppColors.actionBlue),
              const SizedBox(width: 10),
              Text(
                'Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (order.statusHistory.isEmpty)
            _buildTimelineItem(
              'Pending',
              'Order placed',
              order.createdAt,
              true,
              false,
              theme,
              isDark,
            )
          else
            ...List.generate(order.statusHistory.length, (index) {
              final item = order.statusHistory[index];
              final isLatest = index == 0;
              final isLast = index == order.statusHistory.length - 1;
              return _buildTimelineItem(
                item.status,
                item.notes ?? '',
                item.createdAt,
                isLatest,
                isLast,
                theme,
                isDark,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String status,
    String note,
    DateTime date,
    bool isCurrent,
    bool isLast,
    ThemeData theme,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(status);
    final displayColor = isCurrent ? statusColor : Colors.green;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: displayColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_formatDate(date)}, ${_formatTime(date)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                      ),
                    ),
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDisplay(String method) {
    if (method.isEmpty) return tr(context, 'payment_online');
    final m = method.toUpperCase();
    if (m == 'COD' || m.contains('CASH')) {
      return tr(context, 'payment_cod');
    }
    if (m == 'TELR' ||
        m == 'ZIINA' ||
        m.contains('ONLINE') ||
        m.contains('PAY')) {
      return tr(context, 'payment_online');
    }
    return trText(context, method);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildDeliveryAddress(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    final addr = order.shippingAddressDetails;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.actionBlue,
              ),
              const SizedBox(width: 10),
              Text(
                tr(context, 'order_address_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (addr != null) ...[
            Text(
              addr.name ?? tr(context, 'not_provided'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '${addr.line1}, ${addr.line2}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            Text(
              '${addr.city}, ${addr.state}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'phone'),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  addr.phoneNumber ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else
            Text(tr(context, 'order_address_not_avail')),
        ],
      ),
    );
  }

  Future<void> _openReceipt(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open receipt.')),
        );
      }
    }
  }

  Widget _buildPaymentInfo(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    final pay = order.paymentInfo;
    final String status = (pay?.status ?? order.status).toUpperCase();
    final bool isSuccess = ['SUCCESS', 'PAID', 'COMPLETED'].contains(status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                size: 24,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 14),
              Text(
                tr(context, 'order_payment_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Status'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              color: isSuccess
                  ? const Color(0xFFE69728)
                  : (['FAILED', 'CANCELLED'].contains(status)
                        ? Colors.red
                        : Colors.orange),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Method'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getPaymentMethodDisplay(
              order.paymentMethod.isNotEmpty
                  ? order.paymentMethod
                  : (order.paymentInfo?.method ?? 'Online Payment'),
            ),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),

          if (pay?.transactionId != null) ...[
            const SizedBox(height: 20),
            Text(
              'Transaction ID'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pay!.transactionId!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: pay.transactionId!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Transaction ID copied to clipboard',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],

          if (pay?.createdAt != null) ...[
            const SizedBox(height: 20),
            Text(
              'Payment Date'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(pay!.createdAt),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],

          if (order.status.toUpperCase() == 'DELIVERED') ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receipt Ref.'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (order.receiptRef != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.receiptRef!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReceipt(order.receiptImage),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text(
                      'Download Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.8,
                      ),
                      side: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReceipt(order.receiptPdf),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.8,
                      ),
                      side: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (status == 'PENDING') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  String url = order.paymentUrl ?? pay?.paymentUrl ?? '';
                  // ... retry logic (kept same)
                  if (url.isEmpty) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      url = await OrderService().retryPayment(order.id);
                    } catch (e) {
                      debugPrint('Error fetching retry url: $e');
                    }
                    if (mounted) Navigator.pop(context); // close loader
                  }
                  if (url.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to generate payment link. Please contact support.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentWebViewScreen(
                        url: url,
                        title: tr(context, 'secure_payment'),
                        orderId: order.id,
                      ),
                    ),
                  );
                  if (mounted) {
                    final orderIdStr = order.id.toString();
                    if (result == 'success') {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/payment-success',
                        (route) => route.isFirst,
                        arguments: orderIdStr,
                      );
                    } else if (result == 'failed') {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/payment-failed',
                        (route) => route.isFirst,
                        arguments: orderIdStr,
                      );
                    } else if (result == 'pending') {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/order-pending',
                        (route) => route.isFirst,
                        arguments: orderIdStr,
                      );
                    } else {
                      _fetchDetails();
                    }
                  }
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text(
                  'Retry Payment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    OrderModel order,
    ThemeData theme,
    bool isDark,
  ) {
    // Calculate subtotal fallback for older orders
    final double computedSubtotal = order.subTotal > 0
        ? order.subTotal
        : order.items.fold(0.0, (sum, item) => sum + item.subtotal);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1B222E,
        ), // Dark theme-like color for summary box as in screenshot
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'order_summary_title'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          _buildSummaryRow(
            tr(context, 'order_subtotal'),
            'AED ${computedSubtotal.toStringAsFixed(2)}',
            Colors.white,
            0.4,
          ),

          if (order.couponCode != null && order.couponCode!.isNotEmpty)
            _buildSummaryRow(
              trText(context, 'Coupon Applied'),
              order.couponCode!,
              Colors.white,
              0.4,
            ),

          if (order.discountAmount > 0)
            _buildSummaryRow(
              trText(context, 'Discount Amount'),
              '-AED ${order.discountAmount.toStringAsFixed(2)}',
              const Color(0xFF4CAF50),
              0.9,
            ),

          _buildSummaryRow(
            trText(context, 'Delivery Charge'),
            'AED ${order.deliveryCharge.toStringAsFixed(2)}',
            Colors.white,
            0.4,
          ),

          if (order.tipAmount > 0)
            _buildSummaryRow(
              trText(context, 'Tip Amount'),
              'AED ${order.tipAmount.toStringAsFixed(2)}',
              Colors.white,
              0.4,
            ),

          // Always show Delivery Date and Time Slot as requested
          _buildSummaryRow(
            tr(context, 'order_delivery_date'),
            order.preferredDeliveryDate != null &&
                    order.preferredDeliveryDate!.isNotEmpty
                ? order.preferredDeliveryDate!
                : tr(context, 'not_provided'),
            Colors.white,
            0.4,
          ),

          // Replaced _buildSummaryRow with custom multiline layout for Time Slot as per screenshot
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(context, 'order_time_slot'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _resolvedSlotRange ??
                          _getTimeRange(order.preferredDeliverySlot),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((_resolvedSlotLabel != null &&
                            _resolvedSlotLabel!.isNotEmpty) ||
                        _getPeriod(order.preferredDeliverySlot).isNotEmpty)
                      Text(
                        _resolvedSlotLabel ??
                            _getPeriod(order.preferredDeliverySlot),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  tr(context, 'order_total_amount'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AED ${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color color,
    double opacity,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(opacity),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRange(String? slot) {
    if (slot == null || slot.isEmpty) return 'Not Provided';
    if (slot.contains('(')) {
      return slot.substring(0, slot.indexOf('(')).trim();
    }
    return slot;
  }

  String _getPeriod(String? slot) {
    if (slot == null || slot.isEmpty) return '';
    if (slot.contains('(')) {
      return slot.substring(slot.indexOf('(')).trim();
    }
    return '';
  }
}
