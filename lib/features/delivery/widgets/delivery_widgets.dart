import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/delivery/controller/delivery_controller.dart';
import 'package:uae_ecom_project/features/auth/controller/auth_controller.dart';

class DeliveryHeader extends StatelessWidget {
  const DeliveryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Branding
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/home_logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SIMAK FRESH',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3436),
                          height: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining_outlined, size: 10, color: AppColors.actionBlue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'DELIVERY',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.actionBlue,
                                  letterSpacing: 1.2,
                                ),
                              ),
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

          const SizedBox(width: 12),

          // Profile area
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/delivery_profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFF1F2F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PARTNER',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Profile',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.actionBlue,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverGreeting extends StatelessWidget {
  const DriverGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final driverName = user?.firstName ?? 'Driver';
    final deliveryController = context.watch<DeliveryController>();
    final profile = deliveryController.dashboardData?.profile;
    final isAvailable = profile?.isAvailable ?? false;
    final emirates = profile?.assignedEmiratesDisplay.join(', ') ?? 'NO REGION ASSIGNED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 80), // Avoid status badge
                child: Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Hello, ',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$driverName 👋',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.actionBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emirates.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.withOpacity(0.6),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFFE3F9E5) : const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF43D152) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? 'AVAILABLE' : 'OFFLINE',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? const Color(0xFF43D152) : Colors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryStatsGrid extends StatelessWidget {
  const DeliveryStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveryController = context.watch<DeliveryController>();
    final data = deliveryController.dashboardData;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'PENDING ASSIGNED',
                value: '${data?.pendingAssignedOrders ?? 0}',
                icon: Icons.access_time,
                iconColor: AppColors.actionBlue,
                bgColor: Color(0xFFF1FBFF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCard(
                title: 'AVAILABLE NEARBY',
                value: '${data?.availableOrdersInRegion ?? 0}',
                icon: Icons.location_on_outlined,
                iconColor: Colors.grey.shade400,
                bgColor: const Color(0xFFFAFAFA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'COMPLETED TODAY',
                value: '${data?.completedToday ?? 0}',
                icon: Icons.check_circle_outline,
                iconColor: Colors.grey.shade400,
                bgColor: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCard(
                title: 'TOTAL COMPLETED',
                value: '${data?.completedTotal ?? 0}',
                icon: Icons.trending_up,
                iconColor: Colors.grey.shade400,
                bgColor: const Color(0xFFFAFAFA),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding slightly to avoid overflow
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F2F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 8, // Slightly smaller
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3436),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionButtons extends StatelessWidget {
  final VoidCallback onPickUp;
  final VoidCallback onMyDeliveries;

  const QuickActionButtons({
    super.key,
    required this.onPickUp,
    required this.onMyDeliveries,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pick Up Button
        Expanded(
          flex: 4,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), AppColors.actionBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.actionBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPickUp,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.outbox, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'PICK UP NEW ORDER',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // My Deliveries Button
        Expanded(
          flex: 3,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F2F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onMyDeliveries,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'MY DELIVERIES',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecentAssignmentsList extends StatelessWidget {
  const RecentAssignmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveryController = context.watch<DeliveryController>();
    final recentAssignments = deliveryController.dashboardData?.recentAssignments ?? [];

    if (recentAssignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No recent assignments',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentAssignments.map((order) {
        Color statusColor = Colors.grey;
        Color statusBg = const Color(0xFFF5F5F5);

        if (order.status == 'DELIVERED') {
          statusColor = const Color(0xFF43D152);
          statusBg = const Color(0xFFEBFAED);
        } else if (order.status == 'PROCESSING' || order.status == 'SHIPPED') {
          statusColor = const Color(0xFFFF9F43);
          statusBg = const Color(0xFFFFF3E8);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AssignmentCard(
            orderNumber: order.id.toString(),
            status: order.status,
            location: order.shippingAddressDetails?.state ?? 'N/A',
            items: '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
            statusColor: statusColor,
            statusBg: statusBg,
          ),
        );
      }).toList(),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  final String orderNumber;
  final String status;
  final String location;
  final String items;
  final Color statusColor;
  final Color statusBg;

  const AssignmentCard({
    super.key,
    required this.orderNumber,
    required this.status,
    required this.location,
    required this.items,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '#$orderNumber',
                        style: GoogleFonts.outfit(
                          fontSize: 18, // Slightly smaller to prevent overflow
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'RECENT ASSIGNMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$location · $items',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F2F6)),
            ),
            child: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
