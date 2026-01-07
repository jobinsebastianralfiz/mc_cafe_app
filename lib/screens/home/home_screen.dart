import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentNavIndex = 0;
  int _selectedCategoryIndex = 0;
  int _selectedChipIndex = 0;
  int _selectedDrawerIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate loading data
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final List<Map<String, String>> _categories = [
    {'icon': 'assets/images/categories/espresso.png', 'label': 'Espresso'},
    {'icon': 'assets/images/categories/cappuccino.png', 'label': 'Cappuccino'},
    {'icon': 'assets/images/categories/macchiato.png', 'label': 'Macchiato'},
    {'icon': 'assets/images/categories/espresso.png', 'label': 'Mocha'},
    {'icon': 'assets/images/categories/cappuccino.png', 'label': 'Latte'},
  ];

  final List<String> _chips = ['Coffee', 'Drinks', 'Food', 'Combos', 'Desserts'];

  final List<String> _banners = [
    'assets/images/banners/signature_lattes.png',
    'assets/images/banners/delicious_burgers.png',
    'assets/images/banners/signature_lattes.png',
  ];

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
              child: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }

  Widget _buildHeader() {
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
            child: Image.asset(
              'assets/images/avatar.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Hello, ',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Rishan!',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ),
              const Text(
                'Good Afternoon',
                style: TextStyle(
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
        Container(
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
      ],
    );
  }

  Widget _buildBanner() {
    if (_isLoading) {
      return const ShimmerBanner();
    }

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: _banners.length,
          itemBuilder: (context, index) {
            return Container(
              width: MediaQuery.of(context).size.width - 100,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == _banners.length - 1 ? 0 : 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _banners[index],
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
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
          child: _isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => const ShimmerCategoryIcon(),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return AnimatedListItem(
                      index: index,
                      delay: const Duration(milliseconds: 80),
                      child: CategoryIcon(
                        iconPath: _categories[index]['icon']!,
                        label: _categories[index]['label']!,
                        isSelected: _selectedCategoryIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
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
    return SizedBox(
      height: 36,
      child: _isLoading
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const ShimmerChip(),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return AnimatedListItem(
                  index: index,
                  delay: const Duration(milliseconds: 60),
                  child: CategoryChip(
                    label: _chips[index],
                    isSelected: _selectedChipIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedChipIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInWidget(
          delay: const Duration(milliseconds: 400),
          child: const Text(
            'Mocha Coffee',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
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
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return ScaleInWidget(
                    delay: Duration(milliseconds: 100 * index),
                    child: ProductCard(
                      imagePath: 'assets/images/coffee_cup.png',
                      name: 'Mocha Latte',
                      description: 'With Oat Milk',
                      rating: 4.8,
                      price: 4.99,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.productDetail,
                          arguments: {
                            'name': 'Mocha Latte',
                            'description': 'A cappuccino is an approximately 150 ml (5 oz) beverage, with 25 ml of espresso coffee and 85ml of fresh milk',
                            'type': 'Ice/Hot',
                            'price': 4.99,
                            'rating': 4.8,
                            'reviews': 230,
                            'image': 'assets/images/coffee_cup.png',
                          },
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
