import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/utils/feedback_utils.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/widgets/video_player_widget.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/core/widgets/prep_selection_sheet.dart';
import 'package:uae_ecom_project/core/widgets/floating_view_cart_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  late PageController _pageController;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  // Preparation Specification State
  PreparationSpecification? _selectedPreparation;
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  // bool _showPreparationError = false;
  final bool _showFloatingCart = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _prepSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchReviews();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().fetchProductDetail(widget.product.id);
    });
  }

  Future<void> _fetchReviews() async {
    try {
      final controller = context.read<OrderController>();
      final reviews = await controller.fetchProductReviews(widget.product.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  List<_MediaItem> get _media {
    final items = <_MediaItem>[];

    // Add main image first if it exists
    if (widget.product.mainImage != null &&
        widget.product.mainImage!.isNotEmpty) {
      items.add(
        _MediaItem(
          type: _MediaType.image,
          url: widget.product.mainImage!,
          id: -1, // Special ID for main image
        ),
      );
    }

    // Add gallery images (avoiding duplicates if it matches main image)
    for (var img in widget.product.images) {
      if (img.image != widget.product.mainImage) {
        items.add(
          _MediaItem(type: _MediaType.image, url: img.image, id: img.id),
        );
      }
    }

    // Add videos
    items.addAll(
      widget.product.videos.map(
        (e) => _MediaItem(
          type: _MediaType.video,
          url: e.video,
          id: e.id,
          thumbnail: e.thumbnail,
        ),
      ),
    );

    if (items.isEmpty) {
      items.add(
        _MediaItem(
          type: _MediaType.image,
          url: AppConstants.kDefaultProductImage,
          id: 0,
        ),
      );
    }
    return items;
  }

  int get _discountPercent {
    if (widget.product.discountPrice == null || widget.product.price <= 0) {
      return 0;
    }
    return (((widget.product.price - widget.product.finalPrice) /
                widget.product.price) *
            100)
        .round();
  }

  bool get _inStock => widget.product.isAvailable && widget.product.stock > 0;

  /// Returns the quantity of this product already in the cart.
  void _showPrepSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrepSelectionSheet(
        product: widget.product,
        onSelected: (specId, instructions) async {
          final cartController = context.read<CartController>();
          final success = await cartController.addToCart(
            widget.product.id,
            _quantity,
            preparationSpecificationId: specId,
            preparationInstructions: instructions,
          );

          if (!context.mounted) return;
          if (success) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            Navigator.pushNamed(context, '/cart');
          } else {
            if (context.mounted) {
              SimakFeedback.showError(
                context,
                cartController.error ?? 'Failed to add to cart',
              );
            }
          }
        },
      ),
    );
  }

  int _cartQtyForProduct() {
    final cartItems = context.read<CartController>().cart?.items ?? [];
    final existing = cartItems.where((i) => i.product.id == widget.product.id);
    return existing.isEmpty ? 0 : existing.first.quantity;
  }

  /// Shows an error snackbar and returns false if adding [qty] more would
  /// exceed available stock. Returns true when it is safe to proceed.
  bool _canAddMoreToCart(int qty) {
    final existingQty = _cartQtyForProduct();
    final stock = widget.product.stock;
    if (existingQty + qty > stock) {
      SimakFeedback.showError(
        context,
        'Cannot add more. Only $stock ${stock == 1 ? 'item' : 'items'} in stock.',
      );
      return false;
    }
    return true;
  }

  /// Returns true if the user is logged in. Otherwise pops open LoginScreen
  /// and shows a gentle prompt, then returns false.
  bool _requireLogin({required String action}) {
    final auth = context.read<AuthController>();
    if (auth.currentUser != null) return true;

    SimakFeedback.showInfo(
      context,
      '${trStatic(context, 'login_to_action')} $action',
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
      arguments: 2, // 2 is the Profile tab
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = _media;

    return Consumer<ProductController>(
      builder: (context, productController, _) {

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: theme.brightness == Brightness.dark
                    ? [
                        const Color(0xFF001A1F),
                        const Color(0xFF002A35),
                        theme.scaffoldBackgroundColor,
                      ]
                    : [
                        theme.scaffoldBackgroundColor,
                        const Color(0xFFF0F4F5),
                        theme.scaffoldBackgroundColor,
                      ],
              ),
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Gallery header (full-bleed) ──────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // ── Main Media ───────────────────────────
                              SizedBox(
                                height: 280,
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      controller: _pageController,
                                      itemCount: media.length,
                                      onPageChanged: (i) => setState(
                                        () => _currentImageIndex = i,
                                      ),
                                      itemBuilder: (_, index) =>
                                          _buildMediaView(media[index], theme),
                                    ),
                                    // Removed blur/gradient overlays for a cleaner look
                                    // Discount badge
                                    if (_discountPercent > 0)
                                      Positioned(
                                        bottom: 14,
                                        left: 14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.error
                                                    .withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            tr(
                                              context,
                                              'discount_off',
                                              args: {
                                                'percent': _discountPercent
                                                    .toString(),
                                              },
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Video tag
                                    if (media[_currentImageIndex].type ==
                                        _MediaType.video)
                                      Positioned(
                                        bottom: 14,
                                        right: 14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.65,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.play_circle_fill,
                                                color: AppColors.white,
                                                size: 13,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                tr(context, 'video_label'),
                                                style: TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Dot indicators
                                    if (media.length > 1)
                                      Positioned(
                                        bottom: 14,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            media.length,
                                            (i) {
                                              final active =
                                                  i == _currentImageIndex;
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                width: active ? 18 : 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: active
                                                      ? AppColors.white
                                                      : AppColors.white
                                                            .withOpacity(0.45),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // ── Floating App Bar ─────────────────────
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _HeaderButton(
                                            icon: Icons.arrow_back_ios_new,
                                            onTap: () => Navigator.pop(context),
                                            theme: theme,
                                          ),
                                          Row(
                                            children: [
                                              _HeaderButton(
                                                icon: Icons.share_rounded,
                                                onTap: () async {
                                                  final text =
                                                      '*${widget.product.name}*\n'
                                                      'AED ${widget.product.finalPrice}\n\n'
                                                      '${widget.product.description}\n\n'
                                                      '${trStatic(context, 'check_this_out')} https://simakfresh.ae/product/${widget.product.id}\n'
                                                      'Download the app: https://play.google.com/store/apps/details?id=com.simakfresh.app';

                                                  if (widget
                                                              .product
                                                              .mainImage !=
                                                          null &&
                                                      widget
                                                          .product
                                                          .mainImage!
                                                          .isNotEmpty) {
                                                    try {
                                                      final tmpDir =
                                                          Directory.systemTemp;
                                                      final file = File(
                                                        '${tmpDir.path}/shared_product.jpg',
                                                      );
                                                      await Dio().download(
                                                        widget
                                                            .product
                                                            .mainImage!,
                                                        file.path,
                                                      );
                                                      await Share.shareXFiles([
                                                        XFile(file.path),
                                                      ], text: text);
                                                    } catch (e) {
                                                      Share.share(text);
                                                    }
                                                  } else {
                                                    Share.share(text);
                                                  }
                                                },
                                                theme: theme,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Thumbnail strip ─────────────────────────────
                    if (media.length > 1)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 74,
                          margin: const EdgeInsets.only(top: 12),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: media.length,
                            itemBuilder: (_, index) {
                              final isSelected = _currentImageIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : theme.dividerColor,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildThumbnail(media[index], theme),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // ── Product Info Card ───────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category + Stock row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    Provider.of<ProductController>(context, listen: false).getLocalizedCategoryName(context, widget.product.categoryName).toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (widget.product.stock == 0 ||
                                    !widget.product.isAvailable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tr(context, 'out_of_stock'),
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (widget.product.stock < 15)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.warning,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr(
                                            context,
                                            'low_stock',
                                            args: {
                                              'count': widget.product.stock
                                                  .toString(),
                                            },
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Product name
                            Text(
                              widget.product.name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Rating row
                            if (widget.product.rating > 0) ...[
                              Row(
                                children: [
                                  // Stars
                                  Row(
                                    children: List.generate(5, (i) {
                                      final filled =
                                          i < widget.product.rating.round();
                                      return Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.product.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${widget.product.reviewsCount} ${tr(context, 'reviews_label')})',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Price row
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _quantity == 1
                                      ? trStatic(
                                          context,
                                          'Price per ${widget.product.unit.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ')}',
                                        )
                                      : trStatic(
                                          context,
                                          widget.product.unit
                                                  .toLowerCase()
                                                  .contains('kg')
                                              ? 'price_for_quantity_kg'
                                              : 'price_for_quantity_pieces',
                                          args: {'count': _quantity.toString()},
                                        ),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'AED ${(widget.product.finalPrice * _quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (widget.product.discountPrice !=
                                        null) ...[
                                      const SizedBox(width: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        child: Text(
                                          'AED ${(widget.product.price * _quantity).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.45),
                                            fontSize: 16,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // ── Quantity Selector ───────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tr(context, 'quantity'),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          _QtyButton(
                                            icon: Icons.remove,
                                            onTap: _quantity > 1
                                                ? () => setState(
                                                    () => _quantity--,
                                                  )
                                                : null,
                                            theme: theme,
                                          ),
                                          SizedBox(
                                            width: 38,
                                            child: Text(
                                              '$_quantity',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          _QtyButton(
                                            icon: Icons.add,
                                            onTap:
                                                _quantity < widget.product.stock
                                                ? () => setState(
                                                    () => _quantity++,
                                                  )
                                                : null,
                                            theme: theme,
                                            isPrimary: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.product.stock > 0 &&
                                        widget.product.stock < 20) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${widget.product.stock} ${widget.product.unit.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ')} ${trStatic(context, 'in_stock')}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            _buildPreparationSection(theme),

                            const SizedBox(height: 22),

                            // ── Guarantees ──────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.actionBlue
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.electric_moped_rounded,
                                            color: AppColors.actionBlue,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          trStatic(context, '2 Hr Delivery'),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          trStatic(context, 'Fresh Guaranteed'),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── Details ─────────────────────────────
                            _SectionTitle(
                              title: tr(context, 'product_info'),
                              theme: theme,
                            ),
                            const SizedBox(height: 12),
                            _ExpandableText(
                              text: widget.product.description.isNotEmpty
                                  ? widget.product.description
                                  : tr(context, 'default_description'),
                              theme: theme,
                            ),

                            const SizedBox(height: 24),

                            // ── Available Emirates ──────────────────
                            if (widget
                                .product
                                .availableEmirates
                                .isNotEmpty) ...[
                              _SectionTitle(
                                title: trStatic(context, 'Available in'),
                                theme: theme,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                trStatic(
                                  context,
                                  'This product can be delivered in the following emirates:',
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.product.availableEmirates.map((
                                  emirate,
                                ) {
                                  // Format the API string (e.g. 'umm_al_quwain' -> 'Umm Al Quwain')
                                  final rawText = emirate.replaceAll('_', ' ');
                                  final formattedName = rawText
                                      .split(' ')
                                      .map(
                                        (e) => e.isNotEmpty
                                            ? '${e[0].toUpperCase()}${e.substring(1)}'
                                            : '',
                                      )
                                      .join(' ');

                                  // Show "Region" only for Abu Dhabi
                                  final isAbuDhabi =
                                      emirate.toLowerCase().contains(
                                        'abu_dhabi',
                                      ) ||
                                      emirate.toLowerCase().contains(
                                        'abu dhabi',
                                      );
                                  final displayText = isAbuDhabi
                                      ? '$formattedName Region'
                                      : formattedName;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          displayText,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            const SizedBox(height: 24),

                            _buildReviewsSection(theme),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Floating View Cart Bar ─────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FloatingViewCartBar(isVisible: _showFloatingCart),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: theme.dividerColor)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  !_inStock
                      ? Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // If not logged in, navigate to login screen
                              final auth = context.read<AuthController>();
                              if (auth.currentUser == null) {
                                Navigator.pushNamed(
                                  context,
                                  '/login',
                                );
                                return;
                              }

                              final controller = context
                                  .read<ProductController>();
                              final success = await controller.notifyMe(
                                widget.product.id,
                              );

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
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              color: Colors.white,
                            ),
                            label: Text(
                              tr(context, 'notify_me'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            // ── Add to Cart ─────────────────────────
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: _inStock
                                    ? () async {
                                        if (_requireLogin(
                                          action: trStatic(
                                            context,
                                            'action_add_to_cart',
                                          ),
                                        )) {
                                          // MANDATORY: Check if preparation is selected
                                          if (widget
                                              .product
                                              .preparationSpecifications
                                              .isNotEmpty) {
                                            if (_selectedPreparation == null) {
                                              _showPrepSelectionModal();
                                              return;
                                            } else {
                                              // If already selected inline, proceed to add to cart and navigate to Cart page
                                              if (!_canAddMoreToCart(_quantity)) {
                                                return;
                                              }

                                              final cartController = context
                                                  .read<CartController>();

                                              final success = await cartController
                                                  .addToCart(
                                                    widget.product.id,
                                                    _quantity,
                                                    preparationSpecificationId:
                                                        _selectedPreparation?.id,
                                                    preparationInstructions:
                                                        _specialInstructionsController
                                                            .text,
                                                  );
                                              if (!context.mounted) return;
                                              if (success) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/cart',
                                                );
                                              } else {
                                                SimakFeedback.showError(
                                                  context,
                                                  cartController.error ??
                                                      'Failed to add to cart',
                                                );
                                              }
                                              return;
                                            }
                                          }

                                          // Block if adding would exceed stock
                                          if (!_canAddMoreToCart(_quantity)) {
                                            return;
                                          }

                                          final cartController = context
                                              .read<CartController>();

                                          final success = await cartController
                                              .addToCart(
                                                widget.product.id,
                                                _quantity,
                                                preparationSpecificationId:
                                                    _selectedPreparation?.id,
                                                preparationInstructions:
                                                    _specialInstructionsController
                                                        .text,
                                              );
                                          if (!context.mounted) return;
                                          if (success) {
                                            // Visibility is now persistent
                                          } else {
                                            SimakFeedback.showError(
                                              context,
                                              cartController.error ??
                                                  'Failed to add to cart',
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  tr(context, 'add_to_cart'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // ── Buy Now ─────────────────────────────
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _inStock
                                        ? [
                                            AppColors.primary,
                                            AppColors.primaryDark,
                                          ]
                                        : [Colors.grey, Colors.grey.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _inStock
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: _inStock
                                      ? () async {
                                          if (_requireLogin(
                                            action: trStatic(
                                              context,
                                              'action_buy',
                                            ),
                                          )) {
                                            // MANDATORY: Preparation specification check
                                            if (widget
                                                    .product
                                                    .preparationSpecifications
                                                    .isNotEmpty &&
                                                _selectedPreparation == null) {
                                              _showPrepSelectionModal();
                                              return;
                                            }

                                            final existingQty =
                                                _cartQtyForProduct();
                                            final stock = widget.product.stock;

                                            if (existingQty >= stock) {
                                              SimakFeedback.showError(
                                                context,
                                                'Cannot add more. Only $stock '
                                                '${stock == 1 ? 'item' : 'items'} in stock.',
                                              );
                                              if (mounted) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/cart',
                                                );
                                              }
                                              return;
                                            }

                                            final qtyToAdd =
                                                (existingQty + _quantity >
                                                    stock)
                                                ? stock - existingQty
                                                : _quantity;

                                            final cartController = context
                                                .read<CartController>();
                                            final success = await cartController
                                                .addToCart(
                                                  widget.product.id,
                                                  qtyToAdd,
                                                  preparationSpecificationId:
                                                      _selectedPreparation?.id,
                                                  preparationInstructions:
                                                      _specialInstructionsController
                                                          .text,
                                                );

                                            if (!context.mounted) return;

                                            if (success) {
                                              // setState(() => _showFloatingCart = true);
                                              Navigator.pushNamed(
                                                context,
                                                '/cart',
                                              );
                                            } else {
                                              SimakFeedback.showError(
                                                context,
                                                cartController.error ??
                                                    'Failed to add to cart',
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: AppColors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    tr(
                                      context,
                                      _inStock ? 'buy_now' : 'out_of_stock',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
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
          ),
        );
      },
    );
  }

  Widget _buildMediaView(_MediaItem item, ThemeData theme) {
    if (item.type == _MediaType.video) {
      return ProductVideoPlayer(videoUrl: item.url, thumbnail: item.thumbnail);
    }
    return Container(
      color: theme.cardColor,
      child: Center(
        child: CustomImage(
          item.url.isNotEmpty ? item.url : AppConstants.kDefaultProductImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(48.0),
        ),
      ),
    );
  }

  Widget _buildThumbnail(_MediaItem item, ThemeData theme) {
    if (item.type == _MediaType.video) {
      return Stack(
        alignment: Alignment.center,
        children: [
          if (item.thumbnail != null)
            CustomImage(
              item.thumbnail!,
              fit: BoxFit.cover,
              width: 64,
              height: 64,
            )
          else
            Container(color: Colors.black, width: 64, height: 64),
          const Icon(Icons.play_circle, color: AppColors.white, size: 22),
        ],
      );
    }
    return CustomImage(
      item.url,
      fit: BoxFit.cover,
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(8.0),
    );
  }

  Widget _buildPreparationSection(ThemeData theme) {
    // If no preparation options are provided from backend, we might only show special instructions
    // or nothing if the product doesn't support specifications at all.
    // Based on the requirement, we should follow the website UI.

    return Column(
      key: _prepSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.preparationSpecifications.isNotEmpty) ...[
          _SectionTitle(
            title: tr(context, 'preparation_cleaning'),
            theme: theme,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.product.preparationSpecifications.map((spec) {
                final isSelected = _selectedPreparation?.id == spec.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreparation = spec;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.05)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (spec.image != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomImage(
                              spec.image!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      spec.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (spec.extraPrice > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F7FA), // Light cyan
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+AED ${spec.extraPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00ACC1), // Cyan text
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (spec.description != null &&
                                  spec.description!.isNotEmpty)
                                Text(
                                  spec.description!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_selectedPreparation != null) ...[
          _SectionTitle(
            title: tr(context, 'special_instructions_optional'),
            theme: theme,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialInstructionsController,
            decoration: InputDecoration(
              hintText: tr(context, 'special_instructions_hint'),
              hintStyle: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ── Customer Reviews Section ────────────────────────────────────────
  Widget _buildReviewsSection(ThemeData theme) {
    if (!_isLoadingReviews && _reviews.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr(context, 'customer_reviews'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_reviews.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFFFFB800),
                      ),
                    ),
                    Text(
                      ' (${_reviews.length})',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: Colors.grey[350],
                ),
                const SizedBox(height: 10),
                Text(
                  tr(context, 'no_reviews_yet'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'be_the_first_to_review'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            _reviews.length > 5 ? 5 : _reviews.length,
            (index) => _buildReviewCard(_reviews[index], theme, isDark),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review, ThemeData theme, bool isDark) {
    final d = review.createdAt;
    final monthKeys = [
      'month_jan',
      'month_feb',
      'month_mar',
      'month_apr',
      'month_may',
      'month_jun',
      'month_jul',
      'month_aug',
      'month_sep',
      'month_oct',
      'month_nov',
      'month_dec',
    ];
    final dateStr = '${d.day} ${tr(context, monthKeys[d.month - 1])} ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info + rating + date
          Row(
            children: [
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty
                          ? review.userName
                          : tr(context, 'customer_label'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < review.rating
                        ? const Color(0xFFFFB800)
                        : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),

          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          // Review images
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomImage(
                              review.images[i],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImage(
                        review.images[i],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ThemeData theme;
  final bool isPrimary;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.theme,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : enabled
              ? Colors.transparent
              : Colors.transparent,
          borderRadius: isPrimary
              ? const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary
              ? AppColors.white
              : enabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}



class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final ThemeData theme;
  const _ExpandableText({required this.text, required this.theme});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: TextStyle(
              color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        if (widget.text.length > 160) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? tr(context, 'show_less') : tr(context, 'read_more'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


// ─── Models ───────────────────────────────────────────────────────────
enum _MediaType { image, video }

class _MediaItem {
  final _MediaType type;
  final String url;
  final int id;
  final String? thumbnail;

  _MediaItem({
    required this.type,
    required this.url,
    required this.id,
    this.thumbnail,
  });
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          size: 20,
        ),
      ),
    );
  }
}
