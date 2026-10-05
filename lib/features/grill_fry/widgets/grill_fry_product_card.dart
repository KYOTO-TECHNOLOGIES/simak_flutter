import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/utils/feedback_utils.dart';
import 'package:uae_ecom_project/core/widgets/custom_image.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/screens/product_detail_screen.dart';

class GrillFryProductCard extends StatefulWidget {
  final ProductModel product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const GrillFryProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  State<GrillFryProductCard> createState() => _GrillFryProductCardState();
}

class _GrillFryProductCardState extends State<GrillFryProductCard> {
  bool _isHovered = false;

  int get _discountPercent {
    if (widget.product.discountPrice == null || widget.product.price <= 0) {
      return 0;
    }
    return (((widget.product.price - widget.product.finalPrice) /
                widget.product.price) *
            100)
        .round();
  }

  bool get _isGrilled =>
      widget.product.name.toLowerCase().contains('grill');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final qty = widget.quantity;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.actionBlue.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.4),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                spreadRadius: _isHovered ? 2 : 0,
                blurRadius: _isHovered ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Image Container with Badges ─────────────────────────
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F6F8),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        child: CustomImage(
                          p.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),

                    // Gradient Scrim at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-Left: Discount Badge
                    if (_discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-$_discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right: Preparation Tag
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: _isGrilled
                              ? const Color(0xFF003D4D).withOpacity(0.88)
                              : const Color(0xFFC2410C).withOpacity(0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isGrilled ? '🔥' : '🍤',
                              style: const TextStyle(fontSize: 9),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isGrilled ? 'GRILLED' : 'CRISPY FRY',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom-Left on Image: Rating badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              p.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ' (${p.reviewsCount})',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Details Section ─────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            p.name,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),

                          // Short description / unit
                          Text(
                            '${p.unit} • ${p.description}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                              fontSize: 10.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price & Cart Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'AED ',
                                      style: TextStyle(
                                        color: AppColors.actionBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      p.finalPrice.toStringAsFixed(0),
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.discountPrice != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    'AED ${p.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Interactive Add to Cart Stepper / Button
                          _buildCartControl(context, qty),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartControl(BuildContext context, int qty) {
    if (qty > 0) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.actionBlue,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.actionBlue.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                widget.onQuantityChanged(qty - 1);
              },
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$qty',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                widget.onQuantityChanged(qty + 1);
                SimakFeedback.showSuccess(
                  context,
                  '${widget.product.name} quantity: ${qty + 1}',
                );
              },
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onQuantityChanged(1);
          SimakFeedback.showSuccess(
            context,
            '${widget.product.name} ${trStatic(context, 'added_to_cart')}',
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.actionBlue,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.actionBlue.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 3),
              Text(
                'ADD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
