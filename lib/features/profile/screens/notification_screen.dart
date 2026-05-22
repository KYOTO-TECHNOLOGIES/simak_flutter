import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/profile/controller/notification_controller.dart';
import 'package:uae_ecom_project/features/profile/model/notification_model.dart';
import 'package:uae_ecom_project/features/orders/screens/order_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  /// 0 = All, 1 = Unread, 2 = Read
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationController>().fetchMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_outlined, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tr(context, 'notifications'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Consumer<NotificationController>(
            builder: (context, ctrl, _) {
              if (ctrl.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => ctrl.markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  tr(context, 'mark_all_read'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.actionBlue,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, ctrl, _) {
          return RefreshIndicator(
            onRefresh: () => ctrl.fetchNotifications(),
            color: AppColors.actionBlue,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildTabs(ctrl),
                const SizedBox(height: 12),
                Expanded(child: _buildBody(ctrl, theme)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TABS : All | Unread | Read
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildTabs(NotificationController ctrl) {
    final tabs = [
      _TabData(Icons.notifications_outlined, tr(context, 'notifications_all'), ctrl.notifications.length),
      _TabData(Icons.circle_outlined, tr(context, 'notifications_unread'), ctrl.unreadCount),
      _TabData(Icons.done_rounded, tr(context, 'notifications_read'), ctrl.readCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.actionBlue.withOpacity(0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.actionBlue
                        : Colors.grey.shade200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: selected
                          ? AppColors.actionBlue
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.actionBlue
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.actionBlue
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BODY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildBody(NotificationController ctrl, ThemeData theme) {
    if (ctrl.isLoading && ctrl.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.actionBlue),
      );
    }

    final list = _selectedTab == 0
        ? ctrl.notifications
        : _selectedTab == 1
            ? ctrl.unreadNotifications
            : ctrl.readNotifications;

    if (list.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length + (ctrl.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.actionBlue,
              ),
            ),
          );
        }
        return _NotificationCard(
          notification: list[index],
          onOpen: () => _openNotification(ctrl, list[index]),
          onMarkRead: () => ctrl.markAsRead(list[index].id),
          onDelete: () => ctrl.deleteNotification(list[index].id),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    IconData icon;
    switch (_selectedTab) {
      case 1:
        message = tr(context, 'no_unread_notifications');
        icon = Icons.mark_email_read_outlined;
        break;
      case 2:
        message = tr(context, 'no_read_notifications');
        icon = Icons.markunread_mailbox_outlined;
        break;
      default:
        message = tr(context, 'no_notifications_yet');
        icon = Icons.notifications_none_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.actionBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 56, color: AppColors.actionBlue.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              tr(context, 'notification_empty_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  INTERACTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _openNotification(
      NotificationController ctrl, NotificationModel notification) {
    // Mark as read when opening
    if (!notification.isRead) {
      ctrl.markAsRead(notification.id);
    }

    // Navigate to order detail if an order ID is available
    if (notification.orderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: notification.orderId!),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATION CARD WIDGET
// ═══════════════════════════════════════════════════════════════════

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onOpen;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onOpen,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppColors.actionBlue.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade100
              : AppColors.actionBlue.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.grey.shade100
                    : AppColors.actionBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.actionUrl),
                size: 20,
                color: notification.isRead
                    ? Colors.grey.shade400
                    : AppColors.actionBlue,
              ),
            ),
            const SizedBox(width: 14),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.55),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Open button (navigates to order)
                      if (notification.orderId != null)
                        _ActionChip(
                          label: tr(context, 'open_action'),
                          icon: Icons.open_in_new_rounded,
                          color: AppColors.actionBlue,
                          onTap: onOpen,
                        ),
                      if (notification.orderId != null)
                        const SizedBox(width: 8),

                      // Mark as read button
                      if (!notification.isRead)
                        _ActionChip(
                          label: tr(context, 'mark_read'),
                          icon: Icons.done_rounded,
                          color: AppColors.success,
                          onTap: onMarkRead,
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

  IconData _getNotificationIcon(String? actionUrl) {
    if (actionUrl != null && actionUrl.contains('/orders/')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.notifications_outlined;
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTION CHIP (Small Buttons: "Open", "Mark read")
// ═══════════════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INTERNAL TAB DATA
// ═══════════════════════════════════════════════════════════════════

class _TabData {
  final IconData icon;
  final String label;
  final int count;
  const _TabData(this.icon, this.label, this.count);
}
