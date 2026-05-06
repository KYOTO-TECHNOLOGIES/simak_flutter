import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/delivery/widgets/delivery_widgets.dart';
import 'package:uae_ecom_project/features/delivery/widgets/available_orders_view.dart';
import 'package:uae_ecom_project/features/delivery/widgets/my_orders_view.dart';
import 'package:uae_ecom_project/features/orders/controller/order_controller.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryController>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryController = context.watch<DeliveryController>();
    
    return WillPopScope(
      onWillPop: () async {
        if (_activeTab != 0) {
          setState(() => _activeTab = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header Section ──────────────────────────────────────
              const DeliveryHeader(),
  
              // ─── Tab Bar ─────────────────────────────────────────────
              _buildTabBar(),
  
              // ─── Content ─────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (_activeTab == 0) {
                      await context.read<DeliveryController>().fetchDashboard();
                    } else if (_activeTab == 1) {
                      await context.read<DeliveryController>().fetchAvailableOrders();
                    } else if (_activeTab == 2) {
                      final auth = context.read<AuthController>();
                      if (auth.currentUser?.id != null) {
                        await context.read<OrderController>().fetchMyOrders(userId: auth.currentUser!.id!);
                      }
                    }
                  },
                  child: IndexedStack(
                    index: _activeTab,
                    children: [
                      deliveryController.isLoadingDashboard
                          ? const Center(child: CircularProgressIndicator())
                          : _buildDashboardView(),
                      const AvailableOrdersView(),
                      const MyOrdersView(),
                      _buildMyOrdersPlaceholder(),
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

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Greeting
          const DriverGreeting(),
          
          const SizedBox(height: 24),

          // Stats Grid (2x2)
          const DeliveryStatsGrid(),

          const SizedBox(height: 24),

          // Quick Action Buttons
          QuickActionButtons(
            onPickUp: () => setState(() => _activeTab = 1),
            onMyDeliveries: () => setState(() => _activeTab = 2),
          ),

          const SizedBox(height: 32),

          // Recent Assignments List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Assignments',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _activeTab = 2),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.actionBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.actionBlue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const RecentAssignmentsList(),
        ],
      ),
    );
  }

  Widget _buildMyOrdersPlaceholder() {
    return Center(
      child: Text(
        'My Orders View (Coming Soon)',
        style: GoogleFonts.outfit(color: Colors.grey),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F2F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Dashboard', Icons.dashboard_outlined),
          _buildTabItem(1, 'Available', Icons.inventory_2_outlined),
          _buildTabItem(2, 'My Orders', Icons.shopping_bag_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.actionBlue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? AppColors.actionBlue : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isActive)
              Container(
                height: 2,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.actionBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
