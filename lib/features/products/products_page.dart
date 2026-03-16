import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/widgets/fish_loader.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/screens/product_detail_screen.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/auth/screens/login_screen.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProductController>();
      if (controller.products.isEmpty) {
        controller.fetchProducts().then((_) {
          if (mounted) _fadeController.forward();
        });
      } else {
        _fadeController.forward();
      }

      // Check for focusSearch flag in HomeShell arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['focusSearch'] == true) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<ProductController>(
        builder: (context, controller, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Sliver App Bar ──────────────────────────────────
              _buildSliverAppBar(theme, isDark, controller),

              // ─── Category Chips ──────────────────────────────────
              if (controller.products.isNotEmpty)
                _buildCategoryChips(theme, controller),

              // ─── Loading / Error / Content ───────────────────────
              if (controller.isLoading && controller.products.isEmpty)
                SliverFillRemaining(
                  child: FishLoader(message: tr(context, 'loading_products')),
                )
              else if (controller.error != null &&
                  controller.products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, controller.error!),
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => controller.fetchProducts(),
                          icon: const Icon(Icons.refresh),
                          label: Text(tr(context, 'retry')),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // ─── Trending Section ──────────────────────────────
                if (controller.trendingProducts.isNotEmpty)
                  _buildTrendingSection(theme, controller),

                // ─── On Sale Section ───────────────────────────────
                if (controller.onSaleProducts.isNotEmpty)
                  _buildOnSaleSection(theme, controller),

                // ─── All Products Header ───────────────────────────
                _buildSectionHeader(
                  theme,
                  controller.selectedCategory == 'All'
                      ? tr(context, 'all_products')
                      : trText(context, controller.selectedCategory),
                ),

                // ─── Product Grid ──────────────────────────────────
                if (controller.filteredProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.04),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                children: [
                                  Icon(Icons.search_rounded,
                                      color: AppColors.primary.withOpacity(0.1),
                                      size: 80),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: AppColors.error, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              tr(context, 'search_no_results_title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr(context, 'search_no_results_message'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 200, // Reduced width
                              child: ElevatedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                  controller.selectCategory('All');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  tr(context, 'search_clear_filters'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildProductGrid(controller),

                // Bottom padding for nav bar
                const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSliverAppBar(
      ThemeData theme, bool isDark, ProductController controller) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      toolbarHeight: 12,
      elevation: 0,
      scrolledUnderElevation: 2,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.black : theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRect(
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.scaffoldBackgroundColor
                  : theme.scaffoldBackgroundColor,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 58),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8), // Increased from 6
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(12), // Balanced radius
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.set_meal,
                                color: AppColors.white, size: 20), // Increased from 18
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: tr(context, 'app_name_simak'),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const TextSpan(text: ' '),
                                      TextSpan(
                                        text: tr(context, 'app_name_fresh'),
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(context, 'categories_title'),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/cart');
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primary.withOpacity(0.15)),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                // Small Badge showing actual cart count
                                Consumer<CartController>(
                                  builder: (context, controller, child) {
                                    if (controller.itemCount == 0) return const SizedBox.shrink();
                                    return Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${controller.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // ─── Pinned Search Bar ────────────────────────────────────
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          height: 44,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (value) => controller.setSearchQuery(value),
            onSubmitted: (value) {
              controller.setSearchQuery(value);
              FocusScope.of(context).unfocus();
            },
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr(context, 'search_products'),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                      child: Icon(Icons.close,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.4),
                          size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CATEGORY CHIPS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCategoryChips(ThemeData theme, ProductController controller) {
    final categories = controller.categories;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 54,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat == controller.selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => controller.selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : theme.dividerColor,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    trText(context, cat),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TRENDING SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTrendingSection(
      ThemeData theme, ProductController controller) {
    final trending = controller.trendingProducts;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.trending_up, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  tr(context, 'trending_now'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 16),
              ],
            ),
          ),
          SizedBox(
            height: 270,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              itemBuilder: (context, index) {
                final product = trending[index];
                return _TrendingCard(
                  product: product,
                  fallbackImageUrl: controller.fallbackImageUrl,
                  onTap: () => _navigateToDetail(product),
                  onBuyNow: () => _navigateToOrder(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ON SALE SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOnSaleSection(
      ThemeData theme, ProductController controller) {
    final onSale = controller.onSaleProducts;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_offer,
                      color: AppColors.error, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  tr(context, 'on_sale'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${onSale.length}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 16),
              ],
            ),
          ),
          SizedBox(
            height: 155,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: onSale.length,
              itemBuilder: (context, index) {
                final product = onSale[index];
                return _OnSaleCard(
                  product: product,
                  fallbackImageUrl: controller.fallbackImageUrl,
                  onTap: () => _navigateToDetail(product),
                  onBuyNow: () => _navigateToOrder(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(
      ThemeData theme, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRODUCT GRID
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProductGrid(ProductController controller) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = controller.filteredProducts[index];
            return _EnhancedProductCard(
              product: product,
              fallbackImageUrl: controller.fallbackImageUrl,
              onTap: () => _navigateToDetail(product),
              onBuyNow: () => _navigateToOrder(product),
            );
          },
          childCount: controller.filteredProducts.length,
        ),
      ),
    );
  }

  void _navigateToDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _navigateToOrder(ProductModel product, {int quantity = 1}) async {
    if (_requireLogin(action: trStatic(context, 'action_buy'))) {
      // Add to cart first
      final success = await context
          .read<CartController>()
          .addToCart(product.id, quantity);
      
      if (success && mounted) {
        Navigator.pushNamed(
          context,
          '/order',
          arguments: {
            'product': ProductModel.empty(),
            'quantity': 0,
          },
        );
      } else if (mounted) {
        final error = context.read<CartController>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to prepare order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _requireLogin({required String action}) {
    final auth = context.read<AuthController>();
    if (auth.currentUser != null) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${trStatic(context, 'login_to_action')} ${trTextStatic(context, action)}',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false;
  }
}

// ═════════════════════════════════════════════════════════════════════
//  TRENDING CARD  —  Horizontal showcase card
// ═════════════════════════════════════════════════════════════════════
class _TrendingCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;
  final String fallbackImageUrl;

  const _TrendingCard(
      {required this.product,
      required this.onTap,
      required this.onBuyNow,
      required this.fallbackImageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — Hero size
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: product.thumbnail.isNotEmpty
                          ? Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(theme, fallbackImageUrl),
                            )
                          : _placeholder(theme, fallbackImageUrl),
                    ),
                  ),
                  // Floating Tag: "HOT"
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        tr(context, 'hot_label').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Rating Badge — Top Right
                  if (product.rating > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText(context, product.name),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AED ${product.finalPrice}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(tr(context, 'buy_now'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, String fallbackUrl) {
    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: theme.canvasColor,
        child: Center(
          child: Icon(Icons.image_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.2), size: 36),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  ON SALE CARD  —  Compact horizontal sale card
// ═════════════════════════════════════════════════════════════════════
class _OnSaleCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;
  final String fallbackImageUrl;

  const _OnSaleCard(
      {required this.product,
      required this.onTap,
      required this.onBuyNow,
      required this.fallbackImageUrl});

  int get discountPercent {
    if (product.discountPrice == null || product.price <= 0) return 0;
    return (((product.price - product.finalPrice) / product.price) * 100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: double.infinity,
                child: Stack(
                  children: [
                    product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            width: 90,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Image.network(
                              fallbackImageUrl,
                              fit: BoxFit.cover,
                              width: 90,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.canvasColor,
                                child: Icon(Icons.image_outlined,
                                    color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              ),
                            ),
                          )
                        : Image.network(
                            fallbackImageUrl,
                            fit: BoxFit.cover,
                            width: 90,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.canvasColor,
                              child: Icon(Icons.image_outlined,
                                  color: theme.colorScheme.onSurface.withOpacity(0.2)),
                            ),
                          ),
                    // Discount badge
                    if (discountPercent > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product.categoryName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trText(context, product.categoryName).toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      trText(context, product.name),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'AED ${product.finalPrice}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'AED ${product.price}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
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
//  ENHANCED PRODUCT CARD  —  Grid card with badges
// ═════════════════════════════════════════════════════════════════════
class _EnhancedProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;
  final String fallbackImageUrl;

  const _EnhancedProductCard(
      {required this.product,
      required this.onTap,
      required this.onBuyNow,
      required this.fallbackImageUrl});

  int get discountPercent {
    if (product.discountPrice == null || product.price <= 0) return 0;
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22)),
                      child: product.thumbnail.isNotEmpty
                          ? Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(theme, fallbackImageUrl),
                            )
                          : _placeholder(theme, fallbackImageUrl),
                    ),
                  ),
                  // Floating Category Tag
                  if (product.categoryName.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trText(context, product.categoryName).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText(context, product.name),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'AED ${product.finalPrice}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.discountPrice != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'AED ${product.price}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: onBuyNow,
                      icon: const Icon(Icons.flash_on, size: 14),
                      label: Text(tr(context, 'buy_now')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, String fallbackUrl) {
    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: theme.canvasColor,
        child: Center(
          child: Icon(Icons.image_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.2), size: 36),
        ),
      ),
    );
  }
}
