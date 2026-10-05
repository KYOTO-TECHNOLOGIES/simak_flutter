import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/core/widgets/floating_cart_icon.dart';
import 'package:uae_ecom_project/features/grill_fry/data/grill_fry_dummy_data.dart';
import 'package:uae_ecom_project/features/grill_fry/widgets/grill_fry_product_card.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

enum GrillFryFilter { all, grilled, fried, specials }

enum GrillFrySort { featured, priceLowToHigh, priceHighToLow, rating }

class GrillFryCategoryPage extends StatefulWidget {
  const GrillFryCategoryPage({super.key});

  @override
  State<GrillFryCategoryPage> createState() => _GrillFryCategoryPageState();
}

class _GrillFryCategoryPageState extends State<GrillFryCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GrillFryFilter _selectedFilter = GrillFryFilter.all;
  GrillFrySort _selectedSort = GrillFrySort.featured;
  String _searchQuery = '';

  // Local cart item quantities for demo interaction: {productId: quantity}
  final Map<int, int> _cartQuantities = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalCartItems =>
      _cartQuantities.values.fold(0, (sum, count) => sum + count);

  double get _totalCartPrice {
    double total = 0.0;
    for (final entry in _cartQuantities.entries) {
      if (entry.value > 0) {
        final product = GrillFryDummyData.products.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => ProductModel.empty(),
        );
        total += product.finalPrice * entry.value;
      }
    }
    return total;
  }

  List<ProductModel> get _filteredProducts {
    List<ProductModel> list = List.from(GrillFryDummyData.products);

    // Filter by Sub-category
    switch (_selectedFilter) {
      case GrillFryFilter.all:
        break;
      case GrillFryFilter.grilled:
        list = list
            .where((p) => p.name.toLowerCase().contains('grill'))
            .toList();
        break;
      case GrillFryFilter.fried:
        list = list
            .where((p) =>
                p.name.toLowerCase().contains('fried') ||
                p.name.toLowerCase().contains('calamari'))
            .toList();
        break;
      case GrillFryFilter.specials:
        list = list.where((p) => p.rating >= 4.9).toList();
        break;
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    // Sort
    switch (_selectedSort) {
      case GrillFrySort.featured:
        break;
      case GrillFrySort.priceLowToHigh:
        list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case GrillFrySort.priceHighToLow:
        list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case GrillFrySort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic =
        context.watch<LanguageProvider>().locale == 'ar';
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ─── Sliver App Bar ─────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  scrolledUnderElevation: 2,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      color: theme.cardColor,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.08),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          isArabic
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        tr(context, 'cat_grill_and_fry'),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.actionBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HOT KITCHEN',
                          style: TextStyle(
                            color: AppColors.actionBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 16),
                      child: FloatingCartIcon(),
                    ),
                  ],
                ),

                // ─── Hero Showcase Banner ───────────────────────────
                

                // ─── Search & Sort Bar ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchAndSortBar(theme),
                  ),
                ),

                // ─── Filter Tabs (All, Grilled, Fried, Specials) ────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 12),
                    child: _buildFilterTabs(),
                  ),
                ),

                // ─── Section Header with Results Count ──────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.actionBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getFilterTitle(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${products.length} ${products.length == 1 ? "Item" : "Items"}',
                          style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Product Grid ───────────────────────────────────
                if (products.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(theme),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      _totalCartItems > 0 ? 100 : 32,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        int crossAxisCount = 2;
                        if (width > 900) {
                          crossAxisCount = 4;
                        } else if (width > 600) {
                          crossAxisCount = 3;
                        }

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = products[index];
                              return GrillFryProductCard(
                                product: product,
                                quantity: _cartQuantities[product.id] ?? 0,
                                onQuantityChanged: (newQty) {
                                  setState(() {
                                    if (newQty <= 0) {
                                      _cartQuantities.remove(product.id);
                                    } else {
                                      _cartQuantities[product.id] = newQty;
                                    }
                                  });
                                },
                              );
                            },
                            childCount: products.length,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

            // ─── Floating Local Cart Bar ────────────────────────────
            if (_totalCartItems > 0)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildCartBottomBar(context),
              ),
          ],
        ),
      ),
    );
  }

  // ─── HERO BANNER ──────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              'assets/images/grill_and_fry.jpg',
              fit: BoxFit.cover,
            ),

            // Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: Colors.black,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "CHEF'S SIGNATURE PREPARATION",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Headline & Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crispy Fried & Flame Grilled',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Caught fresh, expertly spiced & prepared hot to order.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  // Highlights Badges Row
                  Row(
                    children: [
                      _buildBannerFeaturePill('⚡ 30-45 Mins'),
                      const SizedBox(width: 8),
                      _buildBannerFeaturePill('🔥 Charcoal Grilling'),
                      const SizedBox(width: 8),
                      _buildBannerFeaturePill('🍋 Secret Marinade'),
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

  Widget _buildBannerFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── SEARCH & SORT BAR ────────────────────────────────────────────
  Widget _buildSearchAndSortBar(ThemeData theme) {
    return Row(
      children: [
        // Search TextField
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search grilled fish, calamari, prawns...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.actionBlue,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sort Button
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: PopupMenuButton<GrillFrySort>(
            initialValue: _selectedSort,
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (sort) {
              setState(() {
                _selectedSort = sort;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: GrillFrySort.featured,
                child: Text('Featured'),
              ),
              const PopupMenuItem(
                value: GrillFrySort.priceLowToHigh,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: GrillFrySort.priceHighToLow,
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: GrillFrySort.rating,
                child: Text('Top Rated'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FILTER TABS ──────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final filters = [
      {'type': GrillFryFilter.all, 'label': 'All Items', 'icon': '🍽️'},
      {'type': GrillFryFilter.grilled, 'label': 'Charcoal Grill', 'icon': '🔥'},
      {'type': GrillFryFilter.fried, 'label': 'Crispy Fried', 'icon': '🍤'},
      {'type': GrillFryFilter.specials, 'label': "Chef's Best", 'icon': '⭐'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final type = item['type'] as GrillFryFilter;
          final isSelected = _selectedFilter == type;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = type;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.25),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['icon'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
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

  String _getFilterTitle() {
    switch (_selectedFilter) {
      case GrillFryFilter.all:
        return 'All Grill & Fry Delicacies';
      case GrillFryFilter.grilled:
        return 'Charcoal Flame-Grilled Specials';
      case GrillFryFilter.fried:
        return 'Golden Crispy Fried Favorites';
      case GrillFryFilter.specials:
        return "Chef's Highest-Rated Picks";
    }
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.actionBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.actionBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No seafood dishes match your search',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for pomfret, salmon, king fish or calamari',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedFilter = GrillFryFilter.all;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM CART BAR ──────────────────────────────────────────────
  Widget _buildCartBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Item count & Total Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_totalCartItems ${_totalCartItems == 1 ? "Item" : "Items"} in Cart',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AED ${_totalCartPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: View Cart Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
            icon: const Text(
              'View Cart',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            label: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primaryDark,
              size: 16,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
