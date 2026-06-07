import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/pattern_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.loadFromApi();
      // Mark all as read once they're on screen.
      provider.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationProvider>().loadFromApi();
  }

  void _onNotificationTap(AppNotification notification) {
    // Mark this one as read.
    context.read<NotificationProvider>().markAsRead(notification.id);

    // Order notification → order details.
    if (notification.orderId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.orderDetails,
        arguments: {'orderId': notification.orderId},
      );
      return;
    }

    // Type-based routing for other notification kinds.
    switch (notification.type) {
      case NotificationType.order:
        Navigator.pushNamed(context, AppRoutes.orders);
        return;
      case NotificationType.promotion:
        // Promotion → resolve actionUrl to a known route if possible.
        final route = _routeFromUrl(notification.actionUrl);
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
        return;
      case NotificationType.general:
      case NotificationType.system:
        final route = _routeFromUrl(notification.actionUrl);
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
        return;
    }
  }

  /// Map a backend `data.url` value (e.g. `/offers`) to an app route.
  /// Unknown URLs return null and the tap stays on the notifications list.
  String? _routeFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Strip a leading slash for matching.
    final path = url.startsWith('/') ? url.substring(1) : url;
    switch (path) {
      case 'home':
        return AppRoutes.home;
      case 'products':
      case 'offers':
        return AppRoutes.products;
      case 'cart':
        return AppRoutes.cart;
      case 'wishlist':
        return AppRoutes.wishlist;
      case 'orders':
        return AppRoutes.orders;
      case 'profile':
        return AppRoutes.profile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),

              // Content
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (provider.notifications.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: _buildEmptyState(),
                            ),
                          ],
                        ),
                      );
                    }

                    final itemCount = provider.notifications.length +
                        (provider.hasMore ? 1 : 0);

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingL,
                          vertical: 16,
                        ),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (index >= provider.notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNotificationCard(
                              provider.notifications[index],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textHeading,
                size: 18,
              ),
            ),
          ),

          // Title
          const Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
          ),

          // Clear all button
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty) {
                return const SizedBox(width: 40);
              }
              return GestureDetector(
                onTap: () => _showClearConfirmation(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textHeading,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onNotificationTap(notification),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Image.asset(
              notification.iconAsset,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear All',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to clear all notifications?',
          style: TextStyle(fontFamily: 'Sora'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Sora',
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationProvider>().clearAll();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Sora',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
