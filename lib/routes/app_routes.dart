import 'package:flutter/material.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/redeem_coupon_screen.dart';
import '../screens/address/my_address_screen.dart';
import '../screens/payment/payment_method_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_details_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String redeemCoupon = '/redeem-coupon';
  static const String paymentMethod = '/payment-method';
  static const String myAddress = '/my-address';
  static const String wishlist = '/wishlist';
  static const String notifications = '/notifications';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String checkout = '/checkout';
  static const String orderHistory = '/order-history';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());

      case productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: args),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case redeemCoupon:
        return MaterialPageRoute(builder: (_) => const RedeemCouponScreen());

      case paymentMethod:
        return MaterialPageRoute(builder: (_) => const PaymentMethodScreen());

      case myAddress:
        return MaterialPageRoute(builder: (_) => const MyAddressScreen());

      case wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(order: args),
        );

      // TODO: Add routes as screens are created

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
    }
  }
}
