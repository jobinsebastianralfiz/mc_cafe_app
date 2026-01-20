import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/pattern_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../wishlist/wishlist_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  Timer? _orderPollingTimer;
  int _currentNavIndex = 0;
  int _selectedCategoryIndex = -1; // -1 means "All" selected
  int _selectedDrawerIndex = 0;
  bool _isSearchMode = false;
  String? _lastOrderStatus; // Track last status for vibration

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load home data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startOrderPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _stopOrderPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume polling when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _startOrderPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopOrderPolling();
    }
  }

  void _startOrderPolling() {
    _stopOrderPolling(); // Cancel any existing timer
    // Poll every 30 seconds for order status updates
    _orderPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkOrderStatusUpdate();
    });
  }

  void _stopOrderPolling() {
    _orderPollingTimer?.cancel();
    _orderPollingTimer = null;
  }

  Future<void> _checkOrderStatusUpdate() async {
    final orderProvider = context.read<OrderProvider>();

    // Refresh orders to get latest status
    await orderProvider.loadOrders(refresh: true);

    final updatedOrders = orderProvider.upcomingOrders;
    if (updatedOrders.isEmpty) {
      _lastOrderStatus = null;
      return;
    }

    final newStatus = updatedOrders.first.status.value;

    // Check if status changed
    if (_lastOrderStatus != null && _lastOrderStatus != newStatus) {
      // Vibrate on status change
      HapticFeedback.heavyImpact();
    }

    _lastOrderStatus = newStatus;
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final productProvider = context.read<ProductProvider>();
      if (query.trim().isEmpty) {
        setState(() => _isSearchMode = false);
        productProvider.clearSearch();
      } else {
        setState(() => _isSearchMode = true);
        productProvider.searchProducts(query.trim());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearchMode = false);
    context.read<ProductProvider>().clearSearch();
  }

  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Load product data, cart, and orders in parallel
    await Future.wait([
      productProvider.loadHomeData(),
      cartProvider.loadCart(),
      orderProvider.loadOrders(refresh: true),
    ]);
  }

  Future<void> _refreshData() async {
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Refresh product data, cart, and orders in parallel
    await Future.wait([
      productProvider.loadHomeData(forceRefresh: true),
      cartProvider.loadCart(forceRefresh: true),
      orderProvider.loadOrders(refresh: true),
    ]);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onDrawerItemTap(int index) {
    Navigator.pop(context); // Close drawer

    if (index == -1) {
      // Logout
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (index == 1) {
      // Products
      Navigator.pushNamed(context, AppRoutes.products);
      return;
    }

    if (index == 2) {
      // Orders
      Navigator.pushNamed(context, AppRoutes.orders);
      return;
    }

    if (index == 3) {
      // Notifications
      Navigator.pushNamed(context, AppRoutes.notifications);
      return;
    }

    if (index == 4) {
      // Wishlist
      Navigator.pushNamed(context, AppRoutes.wishlist);
      return;
    }

    if (index == 5) {
      // Profile
      Navigator.pushNamed(context, AppRoutes.profile);
      return;
    }

    if (index == 6) {
      // My Address
      Navigator.pushNamed(context, AppRoutes.myAddress);
      return;
    }

    setState(() {
      _selectedDrawerIndex = index;
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      // Cart - push as separate screen
      Navigator.pushNamed(context, AppRoutes.cart);
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
  }

  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 1:
        return const WishlistScreen(showBottomNav: false);
      case 3:
        return const ProfileScreen(showBottomNav: false);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return PatternBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Header
                        _buildHeader(),

                        const SizedBox(height: 20),

                        // Search bar
                        _buildSearchBar(),

                        const SizedBox(height: 20),

                        // Active Order Banner (if any)
                        _buildActiveOrderBanner(),

                        // Banner
                        _buildBanner(),

                        const SizedBox(height: 24),

                        // Categories section
                        _buildCategoriesSection(),

                        const SizedBox(height: 20),

                        // Category chips
                        _buildCategoryChips(),

                        const SizedBox(height: 20),

                        // Products section
                        _buildProductsSection(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        selectedIndex: _selectedDrawerIndex,
        onItemTap: _onDrawerItemTap,
        onClose: () => Navigator.pop(context),
      ),
      body: _getBodyForIndex(_currentNavIndex),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        cartCount: cartProvider.itemCount,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildHeader() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final firstName = user?.name.split(' ').first ?? 'Guest';

    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipOval(
            child: user?.avatar != null
                ? Image.network(
                    user!.avatar!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(firstName);
                    },
                  )
                : _buildDefaultAvatar(firstName),
          ),
        ),

        const SizedBox(width: 12),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Hello, ',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$firstName!',
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ),
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Notification icon
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: Image.asset(
            'assets/icons/notification.png',
            width: 24,
            height: 24,
          ),
        ),

        const SizedBox(width: 16),

        // Menu icon
        GestureDetector(
          onTap: _openDrawer,
          child: Image.asset(
            'assets/icons/menu.png',
            width: 24,
            height: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Eg:- Coffee, Drinks etc...',
                      hintStyle: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        color: AppColors.grey.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: _isSearchMode
                          ? GestureDetector(
                              onTap: _clearSearch,
                              child: const Icon(
                                Icons.close,
                                color: AppColors.grey,
                                size: 18,
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showFilterBottomSheet,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/filter.png',
                width: 20,
                height: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOrderBanner() {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders = orderProvider.upcomingOrders;

    if (activeOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show the most recent active order
    final order = activeOrders.first;

    // Update last status for tracking
    if (_lastOrderStatus == null) {
      _lastOrderStatus = order.status.value;
    }

    // Determine colors based on status
    final isReadyOrDelivery = order.status == OrderStatus.ready ||
        order.status == OrderStatus.outForDelivery;

    final gradientColors = isReadyOrDelivery
        ? [const Color(0xFF4CAF50), const Color(0xFF81C784)] // Green gradient
        : [AppColors.primary, const Color(0xFFD4A574)]; // Default brown gradient

    final shadowColor = isReadyOrDelivery
        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.3);

    final statusBadgeColor = isReadyOrDelivery
        ? const Color(0xFF4CAF50)
        : AppColors.primary;

    final statusIcon = isReadyOrDelivery
        ? Icons.check_circle
        : Icons.receipt_long;

    final statusLabel = isReadyOrDelivery
        ? (order.status == OrderStatus.ready ? 'Ready for Pickup!' : 'Out for Delivery!')
        : 'Active Order';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.orderDetails,
            arguments: {
              'orderId': order.id,
              'order': order,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Order Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.formattedToken != null
                          ? 'Token: ${order.formattedToken}'
                          : 'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusBadgeColor,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        onApply: (minPrice, maxPrice, sortBy) {
          final productProvider = context.read<ProductProvider>();
          productProvider.loadProducts(
            minPrice: minPrice,
            maxPrice: maxPrice,
            sort: sortBy,
            refresh: true,
          );
          setState(() {
            _selectedCategoryIndex = -1;
            _isSearchMode = false;
          });
          _searchController.clear();
        },
      ),
    );
  }

  Widget _buildBanner() {
    final productProvider = context.watch<ProductProvider>();
    final banners = productProvider.banners;
    final isLoading = productProvider.bannersStatus == LoadingStatus.loading;

    if (isLoading && banners.isEmpty) {
      return const ShimmerBanner();
    }

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            final imageUrl = ApiConfig.getImageUrl(banner.image);
            debugPrint('🖼️ Banner ${banner.id}: image=${banner.image}, url=$imageUrl');

            return Container(
              width: MediaQuery.of(context).size.width - 100,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == banners.length - 1 ? 0 : 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.lightGrey,
                          highlightColor: AppColors.white,
                          child: Container(
                            height: 140,
                            color: AppColors.lightGrey,
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildBannerPlaceholder(banner.title),
                      )
                    : _buildBannerPlaceholder(banner.title),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder(String title) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;
    final isLoading = productProvider.categoriesStatus == LoadingStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          child: const Text(
            'Categories',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: isLoading && categories.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => const ShimmerCategoryIcon(),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return AnimatedListItem(
                      index: index,
                      delay: const Duration(milliseconds: 80),
                      child: CategoryIcon(
                        imageUrl: ApiConfig.getImageUrl(category.image),
                        label: category.name,
                        isSelected: _selectedCategoryIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                          // Load products for this category
                          productProvider.loadProducts(
                            categoryId: category.id,
                            refresh: true,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;
    final isLoading = productProvider.categoriesStatus == LoadingStatus.loading;

    return SizedBox(
      height: 36,
      child: isLoading && categories.isEmpty
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const ShimmerChip(),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              // +1 for "All" chip at the start
              itemCount: categories.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                // First item is "All"
                if (index == 0) {
                  return AnimatedListItem(
                    index: index,
                    delay: const Duration(milliseconds: 60),
                    child: CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryIndex == -1,
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = -1;
                        });
                        // Load all featured products
                        productProvider.loadFeaturedProducts(forceRefresh: true);
                      },
                    ),
                  );
                }
                final category = categories[index - 1];
                return AnimatedListItem(
                  index: index,
                  delay: const Duration(milliseconds: 60),
                  child: CategoryChip(
                    label: category.name,
                    isSelected: _selectedCategoryIndex == index - 1,
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index - 1;
                      });
                      // Load products for this category
                      productProvider.loadProducts(
                        categoryId: category.id,
                        refresh: true,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductsSection() {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;

    // Determine which products to show based on mode
    List products;
    bool isLoading;
    String sectionTitle;

    if (_isSearchMode) {
      // Search mode
      products = productProvider.searchResults;
      isLoading = productProvider.searchStatus == LoadingStatus.loading;
      sectionTitle = 'Search Results';
    } else if (_selectedCategoryIndex == -1) {
      // Featured mode
      products = productProvider.featuredProducts;
      isLoading = productProvider.featuredStatus == LoadingStatus.loading;
      sectionTitle = 'Featured';
    } else {
      // Category mode
      products = productProvider.products;
      isLoading = productProvider.productsStatus == LoadingStatus.loading;
      sectionTitle = _selectedCategoryIndex < categories.length
          ? categories[_selectedCategoryIndex].name
          : 'Products';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInWidget(
          delay: const Duration(milliseconds: 400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
              if (!_isSearchMode && _selectedCategoryIndex >= 0 && _selectedCategoryIndex < categories.length)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.products,
                      arguments: {
                        'categoryId': categories[_selectedCategoryIndex].id,
                        'categoryName': categories[_selectedCategoryIndex].name,
                      },
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        isLoading && products.isEmpty
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => const ShimmerProductCard(),
              )
            : products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length > 6 ? 6 : products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ScaleInWidget(
                        delay: Duration(milliseconds: 100 * index),
                        child: ProductCard(
                          imageUrl: ApiConfig.getImageUrl(product.image),
                          name: product.name,
                          description: product.shortDescription,
                          rating: 4.5, // TODO: Add rating to product model if API supports
                          price: product.priceAsDouble,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.productDetail,
                              arguments: {
                                'slug': product.slug,
                                'product': product,
                              },
                            );
                          },
                          onAddTap: () {
                            // Add to cart
                            final cartProvider = context.read<CartProvider>();
                            cartProvider.addToCart(product: product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}

/// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final Function(double? minPrice, double? maxPrice, String? sortBy) onApply;

  const _FilterBottomSheet({required this.onApply});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 50);
  String _selectedSort = 'newest';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'oldest', 'label': 'Oldest First'},
    {'value': 'price_low', 'label': 'Price: Low to High'},
    {'value': 'price_high', 'label': 'Price: High to Low'},
    {'value': 'name_asc', 'label': 'Name: A to Z'},
    {'value': 'name_desc', 'label': 'Name: Z to A'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 50);
                    _selectedSort = 'newest';
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '£${_priceRange.start.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '£${_priceRange.end.toInt()}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          const SizedBox(height: 24),

          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _selectedSort == option['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSort = option['value']!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(
                  _priceRange.start,
                  _priceRange.end,
                  _selectedSort,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply Filter',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
