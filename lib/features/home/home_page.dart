import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/core/widgets/fish_loader.dart';
import 'package:uae_ecom_project/features/auth/screens/login_screen.dart';
import 'package:uae_ecom_project/features/marketing/controller/marketing_controller.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/screens/product_detail_screen.dart';
import 'package:uae_ecom_project/features/home/widgets/promo_popup_dialog.dart';
import 'package:uae_ecom_project/features/home/screens/all_popular_products_page.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/core/widgets/quick_add_to_cart_button.dart';
import 'package:uae_ecom_project/core/widgets/floating_cart_icon.dart';
import 'package:uae_ecom_project/features/home/widgets/how_it_works_section.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';
import 'package:uae_ecom_project/features/auth/widgets/name_input_dialog.dart';
import 'package:uae_ecom_project/features/home/widgets/language_selection_icon.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/emirate/controller/emirate_controller.dart';
import 'package:uae_ecom_project/core/widgets/quick_add_to_cart_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasShownPromo = false;
  static bool _hasShownNameDialog = false;
  bool _promoScheduledThisSession = false;

  @override
  void initState() {
    super.initState();
    // Fetch products once when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emirate = context.read<EmirateController>().selectedEmirate;
      context.read<ProductController>().fetchProducts(emirate: emirate);
      context.read<ProductController>().fetchCategories();
      context.read<MarketingController>().fetchBanners();
      context.read<OrderController>().fetchHomeReviews();
      _schedulePromoPopup();
    });
  }

  void _showNameDialogIfNeeded() {
    if (_hasShownNameDialog) return;

    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) return;

    final user = auth.currentUser;
    if (user == null) return;

    // Check if user has both first and last name empty
    if (user.firstName.trim().isEmpty && user.lastName.trim().isEmpty) {
      _hasShownNameDialog = true;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const NameInputDialog(),
      );
    }
  }


  void _schedulePromoPopup() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      // If promo already shown or we don't want to show it, trigger fallback eventually
      if (_hasShownPromo) {
        _showNameDialogIfNeeded();
        return;
      }

      final marketingController = context.read<MarketingController>();

      void tryShow() {
        if (!mounted || _hasShownPromo) return;
        final popups = marketingController.popups;

        if (popups.isEmpty) {
          // If no promo found after fetch, show the name dialog immediately as fallback
          _showNameDialogIfNeeded();
          return;
        }

        final activePopup = popups.first;
        _hasShownPromo = true;
        _promoScheduledThisSession = true;

        PromoPopupDialog.showAfterDelay(
          context: context,
          marketing: activePopup,
          delay: Duration.zero,
          onShopNow: () {
            if (activePopup.link != null && activePopup.link!.isNotEmpty) {
              if (activePopup.link!.startsWith('http')) {
                // Open browser or handle external link
              } else {
                Navigator.pushNamed(context, activePopup.link!);
              }
            }
          },
        ).then((_) {
          if (!mounted) return;
          final auth = context.read<AuthController>();

          if (auth.isLoggedIn) {
            // Priority: Wait for promo to be fully dismissed
            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              _showNameDialogIfNeeded();
            });
          } else {
            _showGuestNotification();
          }
        });
      }

      if (!marketingController.isLoading) {
        tryShow();
      } else {
        void listener() {
          if (!marketingController.isLoading) {
            marketingController.removeListener(listener);
            tryShow();
          }
        }

        marketingController.addListener(listener);
        
        // Safety timeout for the name dialog if backend fetch hangs too long
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && marketingController.isLoading && !_hasShownPromo) {
             _showNameDialogIfNeeded();
          }
        });
      }
    });
  }

  void _showGuestNotification() async {
    // Wait for 2 seconds after the ad closes
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthController>();
    if (auth.isLoggedIn) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _GuestPromptOverlay(
          onDismiss: () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          },
          onSignIn: () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              final emirate = context.read<EmirateController>().selectedEmirate;
              await Future.wait([
                context.read<ProductController>().fetchProducts(emirate: emirate),
                context.read<ProductController>().fetchCategories(),
                context.read<MarketingController>().fetchBanners(),
                context.read<OrderController>().fetchHomeReviews(),
              ]);
            },
            color: AppColors.primary,
            child: CustomScrollView(
            slivers: [
              // ─── App Bar ─────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                automaticallyImplyLeading: false,
                toolbarHeight: 80,
                title: Padding(
                  padding: const EdgeInsets.only(
                    left: 7,
                    top: 4,
                  ), // Breathing room
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/home_logo.png',
                                height: 30,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: IntrinsicWidth(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                tr(
                                                  context,
                                                  'app_name_simak',
                                                ).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 45,
                                                  fontWeight: FontWeight.w900,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                  height: 1.0,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                tr(
                                                  context,
                                                  'app_name_fresh',
                                                ).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 45,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.actionBlue,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          FittedBox(
                                            fit: BoxFit.fitWidth,
                                            child: Text(
                                              tr(
                                                context,
                                                'tagline',
                                              ).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.actionBlue,
                                                letterSpacing: 1.0,
                                                height: 1.0,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                        const Spacer(),
                        // Language Selection Icon (Always visible)
                        const Padding(
                          padding: EdgeInsets.only(right: 9),
                          child: LanguageSelectionIcon(),
                        ),
                        // Floating Animated Cart Icon
                        const FloatingCartIcon(),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Search Bar ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to Products tab in HomeShell with auto-focus flag
                      Navigator.pushReplacementNamed(
                        context,
                        '/home',
                        arguments: {'index': 1, 'focusSearch': true},
                      );
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tr(context, 'search_hint'),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Banner Slider ────────────────────────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(child: _BannerSlider()),
              ),

              // ─── Categories ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'shop_by_category'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: Consumer<ProductController>(
                          builder: (context, controller, child) {
                            if (controller.isCategoriesLoading &&
                                controller.backendCategories.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final categories = controller.backendCategories;
                            if (categories.isEmpty) {
                              return Center(
                                child: Text(
                                  tr(context, 'no_categories'),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _CategoryCard(
                                  index: index,
                                  imageUrl:
                                      category.image ??
                                      AppConstants.kDefaultProductImage,
                                  label: category.name,
                                  onTap: () {
                                    // Set selected category and navigate
                                    controller.selectCategory(category.name);
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                      arguments: {'index': 1},
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Product Grid Title ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(context, 'popular_now'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllPopularProductsPage(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr(context, 'see_all'),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Product Grid (limited to 4) ──────────────────────
              Consumer<ProductController>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: FishLoader(
                          message: tr(context, 'loading_products'),
                        ),
                      ),
                    );
                  }

                  if (controller.error != null && controller.products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            controller.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller.products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            tr(context, 'no_products'),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Show only up to 4 products on the home page
                  final displayCount = controller.products.length < 4
                      ? controller.products.length
                      : 4;

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.7,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = controller.products[index];
                        return _ProductCard(
                          product: product,
                          fallbackImageUrl: controller.fallbackImageUrl,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        );
                      }, childCount: displayCount),
                    ),
                  );
                },
              ),

              // ─── How It Works ──────────────────────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(child: HowItWorksSection()),
              ),

              // ─── Why Choose Us ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(child: _WhyChooseUs()),
              ),

              // ─── Stats Bar (New) ────────────────────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(child: _HomeStatsBar()),
              ),

              // ─── Highlighted Testimonial (New) ──────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(child: _HighlightedTestimonial()),
              ),

              // ─── User Reviews ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(child: _UserReviews()),
              ),

              // ─── Featured Recipe ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  32,
                  20,
                  100,
                ), // Keep 100 padding at the very bottom
                sliver: SliverToBoxAdapter(child: _FeaturedRecipe()),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _CategoryCard extends StatefulWidget {
  final int index;
  final String imageUrl;
  final String label;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.index,
    required this.imageUrl,
    required this.label,
    this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _floatingAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Start floating after entry animation delay
    Future.delayed(Duration(milliseconds: 600 + (widget.index * 150)), () {
      if (mounted) _floatingController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (widget.index * 150)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.primary.withOpacity(0.05),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary.withOpacity(0.05),
                          child: Icon(
                            Icons.set_meal_rounded,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final String fallbackImageUrl;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.fallbackImageUrl,
  });

  bool get _inStock => product.isAvailable && product.stock > 0;

  int get discountPercent {
    if (product.price <= 0 || product.finalPrice >= product.price) return 0;
    return (((product.price - product.finalPrice) / product.price) * 100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network(
                                  fallbackImageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: theme.cardColor,
                                        child: const Icon(Icons.error_outline),
                                      ),
                                ),
                          )
                        : Image.network(
                            fallbackImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: theme.cardColor,
                                  child: const Icon(Icons.error_outline),
                                ),
                          ),
                  ),
                  // Discount badge
                  if (discountPercent > 0 && _inStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Add to Cart Button — Top Right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: QuickAddToCartButton(product: product),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText(context, product.name),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (discountPercent > 0 && _inStock)
                        Text(
                          'AED ${product.price}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        )
                      else
                        const SizedBox(height: 15),

                      const SizedBox(height: 2),
                      Text(
                        'AED ${product.finalPrice}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

// ═════════════════════════════════════════════════════════════════════
//  ANIMATED BANNER SLIDER
// ═════════════════════════════════════════════════════════════════════

class _BannerSlider extends StatefulWidget {
  const _BannerSlider();

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider>
    with TickerProviderStateMixin {
  static const int _infiniteCount = 10000;
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _initialized = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _pageController = PageController();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = ((screenWidth - 40) * 0.52).clamp(200.0, 280.0);

    return Consumer<MarketingController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.banners.isEmpty) {
          return SizedBox(
            height: bannerHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.banners.isEmpty) {
          return const SizedBox.shrink();
        }

        // Initialize to middle once banners are loaded
        if (!_initialized && controller.banners.isNotEmpty) {
          _initialized = true;
          final bannersCount = controller.banners.length;
          final initialPage =
              (_infiniteCount ~/ 2) - ((_infiniteCount ~/ 2) % bannersCount);
          _currentPage = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(initialPage);
              _startAutoPlay();
            }
          });
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                SizedBox(
                  height: bannerHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _infiniteCount,
                    onPageChanged: (i) {
                      setState(
                        () => _currentPage = i % controller.banners.length,
                      );
                      _fadeController
                        ..reset()
                        ..forward();
                    },
                    itemBuilder: (context, index) {
                      final banners = controller.banners;
                      if (banners.isEmpty) return const SizedBox.shrink();
                      final slide = banners[index % banners.length];
                      return _BannerSlide(slide: slide, fadeAnim: _fadeAnim);
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
            // Dot indicators on the left
            Positioned(
              left: 40,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(controller.banners.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isActive ? 1.0 : 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final MarketingModel slide;
  final Animation<double> fadeAnim;

  const _BannerSlide({required this.slide, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              slide.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003038), Color(0xFF001519)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),
              ),
            ),

            // Dark gradient overlay (stronger on left)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7],
                ),
              ),
            ),

            // Content with fade animation
            FadeTransition(
              opacity: fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Tags row ─────────────────────────────
                    if ((slide.tag != null && slide.tag!.isNotEmpty) ||
                        (slide.type != null && slide.type!.isNotEmpty)) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (slide.tag != null && slide.tag!.isNotEmpty)
                            _buildPillTag(slide.tag!, AppColors.accent),
                          if (slide.type != null && slide.type!.isNotEmpty)
                            _buildPillTag(
                              slide.type!,
                              Colors.white.withOpacity(0.15),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Headline ─────────────────────────────
                    if (slide.title != null)
                      Flexible(
                        child: Text(
                          slide.title!,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22, // Slightly smaller for better fit
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // ── Subtitle ─────────────────────────────
                    if (slide.subtitle != null)
                      Flexible(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(
                            slide.subtitle!,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12, // Slightly smaller for better fit
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // ── CTA Button ───────────────────────────
                    if (slide.ctaText != null)
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Handle CTA link
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(
                            0,
                            36,
                          ), // Ensure it stays compact
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.ctaText!,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 14),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── New Attractive Sections ─────────────────────────────────────────

class _WhyChooseUs extends StatelessWidget {
  const _WhyChooseUs();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'why_choose'),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildBenefitCard(
              context,
              Icons.bolt_rounded,
              tr(context, 'benefit_delivery'),
              tr(context, 'benefit_delivery_sub'),
              const Color(0xFFE8F5E9),
              Colors.green.shade700,
            ),
            const SizedBox(width: 12),
            _buildBenefitCard(
              context,
              Icons.verified_user_rounded,
              tr(context, 'benefit_premium'),
              tr(context, 'benefit_premium_sub'),
              const Color(0xFFFFF3E0),
              AppColors.accent,
            ),
            const SizedBox(width: 12),
            _buildBenefitCard(
              context,
              Icons.set_meal_rounded,
              tr(context, 'benefit_fresh'),
              tr(context, 'benefit_fresh_sub'),
              const Color(0xFFE3F2FD),
              Colors.blue.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedRecipe extends StatelessWidget {
  const _FeaturedRecipe();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=800&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tr(context, 'recipe_of_day'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'recipe_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  tr(context, 'recipe_time'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tr(context, 'view_steps'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserReviews extends StatelessWidget {
  const _UserReviews();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'what_customers_say'),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<OrderController>(
          builder: (context, controller, _) {
            final reviews = controller.homeReviews;

            if (controller.isLoading && reviews.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (reviews.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 200, // Slightly taller to account for product badge
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: min(
                  reviews.length,
                  10,
                ), // Show up to 10 latest reviews
                padding: EdgeInsets.zero,
                clipBehavior: Clip.none,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(context, review, theme);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    ReviewModel review,
    ThemeData theme,
  ) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Row
          Row(
            children: [
              ...List.generate(5, (starIndex) {
                return Icon(
                  starIndex < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 18,
                );
              }),
              const Spacer(),
              const Icon(
                Icons.format_quote_rounded,
                color: Color(0xFFE0E0E0),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Comment
          Expanded(
            child: Text(
              review.comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Product Badge
          if (review.productName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.actionBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 10,
                    color: AppColors.actionBlue.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      review.productName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.actionBlue.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // User Info
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty
                          ? review.userName
                          : 'Anonymous',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green.shade600,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr(context, 'verified_customer'),
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _getTimeAgo(review.createdAt),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

class _HomeStatsBar extends StatelessWidget {
  const _HomeStatsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF003038), // Dark navy blue from screenshot
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 350;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('25,000+', tr(context, 'stat_happy_customers')),
              _buildStatItem('50+', tr(context, 'stat_seafood_varieties')),
              _buildStatItem('4.8★', tr(context, 'stat_average_rating')),
              _buildStatItem('98%', tr(context, 'stat_ontime_delivery')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFB300), // Gold/Amber color
                fontSize: 20, // Increased from 18
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(), // Using uppercase for better fit
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 9, // Slightly increased from 8
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedTestimonial extends StatelessWidget {
  const _HighlightedTestimonial();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (_) => const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB300), // Gold/Amber color
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            tr(context, 'testimonial_quote'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, 'testimonial_author'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr(context, 'verified_purchase'),
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withOpacity(0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Guest Prompt Overlay ──────────────────────────────────────────
class _GuestPromptOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onSignIn;

  const _GuestPromptOverlay({required this.onDismiss, required this.onSignIn});

  @override
  State<_GuestPromptOverlay> createState() => _GuestPromptOverlayState();
}

class _GuestPromptOverlayState extends State<_GuestPromptOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Auto-dismiss after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  void _handleDismiss() async {
    if (_controller.isAnimating) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr(context, 'unlock_features'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          tr(context, 'join_members'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CTA
                  TextButton(
                    onPressed: widget.onSignIn,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: Text(tr(context, 'sign_in')),
                  ),
                  // Close
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 16,
                    ),
                    onPressed: _handleDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
