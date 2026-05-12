import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/features/auth/controller/address_controller.dart';
import 'package:uae_ecom_project/features/home/home_page.dart';
import 'package:uae_ecom_project/features/products/controller/product_controller.dart';
import 'package:uae_ecom_project/features/products/products_page.dart';
import 'package:uae_ecom_project/features/profile/profile_screen.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/cart/controller/cart_controller.dart';

/// Shell widget that holds the three main tabs with an animated bottom nav bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _profileSection = 0;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartController>().fetchCart();
      context.read<AddressController>().fetchAddresses();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _currentIndex = args;
      } else if (args is Map<String, dynamic>) {
        _currentIndex = args['index'] ?? 0;
        _profileSection = args['profileSection'] ?? 0;
      }
      _isInit = false;
    }
  }

  // Keep pages alive for smooth transitions
  List<Widget> get _pages => [
    const HomePage(),
    const ProductsPage(),
    ProfileScreen(initialSection: _profileSection),
  ];

  List<_NavItemData> _getNavItems(BuildContext context) => [
    _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: tr(context, 'nav_home')),
    _NavItemData(icon: Icons.store_outlined, activeIcon: Icons.store, label: tr(context, 'nav_products')),
    _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: tr(context, 'nav_profile')),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    // Reset product filters when switching to the Products tab.
    // Done in a post-frame callback to avoid notifyListeners conflicts
    // with the ongoing setState rebuild.
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ProductController>(context, listen: false).clearFilters();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Always navigate to home tab instead of closing app
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false; // Prevent default back behavior
        }
        // If already on home tab, allow default behavior (will show exit dialog)
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _pages[_currentIndex],
          ),
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_getNavItems(context).length, (index) {
              return _NavItem(
                data: _getNavItems(context)[index],
                isSelected: _currentIndex == index,
                onTap: () => _onTabTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Data class for nav items ───────────────────────────────────
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─── Single nav item with animations ────────────────────────────
class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.actionBlue.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isSelected ? data.activeIcon : data.icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.actionBlue : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          data.label,
                          style: const TextStyle(
                            color: AppColors.actionBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
