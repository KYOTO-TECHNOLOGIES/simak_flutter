import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';

class FloatingCartIcon extends StatefulWidget {
  const FloatingCartIcon({super.key});

  @override
  State<FloatingCartIcon> createState() => _FloatingCartIconState();
}

class _FloatingCartIconState extends State<FloatingCartIcon>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();

    // ─── Floating (Bobbing) Animation ────────────────────
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // ─── Pulse (Item Added) Animation ────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onItemCountChanged(int count) {
    if (count > _lastItemCount) {
      _pulseController.forward(from: 0.0);
    }
    _lastItemCount = count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CartController>(
      builder: (context, controller, child) {
        // Trigger pulse if items were added
        if (controller.itemCount != _lastItemCount) {
          _onItemCountChanged(controller.itemCount);
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_floatController, _pulseController]),
          builder: (context, child) {
            final floatValue = _floatAnimation.value;
            // Normalize floatValue from [-6, 6] to [0, 1] for shadow/rotation
            final normalized = (floatValue + 6) / 12;

            return Transform.translate(
              offset: Offset(0, floatValue),
              child: Transform.rotate(
                angle: 0.03 * (normalized - 0.5), // Gentler tilt
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The main cart vessel with Dynamic Shadow
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                // Sustained premium shadow with subtle variance
                                color: AppColors.primary.withOpacity(0.06 + (0.04 * normalized)),
                                blurRadius: 12 + (6 * normalized),
                                offset: Offset(0, 5 + (5 * normalized)),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_cart_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        
                        // Animated Badge
                        if (controller.itemCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${controller.itemCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
