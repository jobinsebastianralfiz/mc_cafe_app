# MaiCafe API Implementation Plan

## Table of Contents
1. [Overview](#overview)
2. [Project Architecture](#project-architecture)
3. [Folder Structure](#folder-structure)
4. [Configuration Classes](#configuration-classes)
5. [Core Classes](#core-classes)
6. [Data Models](#data-models)
7. [Repositories](#repositories)
8. [Providers (State Management)](#providers-state-management)
9. [Services](#services)
10. [Route Management](#route-management)
11. [API Endpoints Reference](#api-endpoints-reference)
12. [Authentication Flow](#authentication-flow)
13. [Error Handling](#error-handling)
14. [Implementation Priority](#implementation-priority)

---

## Overview

This document provides a comprehensive implementation plan for integrating the MaiCafe backend API into the Flutter application using **Provider** for state management and **SharedPreferences** for local storage.

### Key Principles
- **No hardcoding** - All values in configuration classes
- **Class-based architecture** - Everything organized in classes
- **Provider state management** - Centralized state with ChangeNotifier
- **Repository pattern** - Separation of data layer from UI
- **Route management** - Using `onGenerateRoute` with `AppRoutes` class

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│                   (Screens & Widgets)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    Provider Layer                           │
│              (State Management - Notifiers)                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Repository Layer                          │
│            (Business Logic & Data Handling)                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    Service Layer                            │
│              (API Calls & Local Storage)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                     Data Layer                              │
│                (Models & DTOs)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── api_config.dart              # API URLs, endpoints
│   ├── app_config.dart              # App-wide configuration
│   ├── storage_keys.dart            # SharedPreferences keys
│   └── theme/
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── enums/
│   │   ├── order_status.dart
│   │   ├── payment_method.dart
│   │   ├── payment_status.dart
│   │   └── order_type.dart
│   ├── exceptions/
│   │   └── api_exception.dart
│   └── utils/
│       ├── validators.dart
│       └── helpers.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── category_model.dart
│   │   ├── product_model.dart
│   │   ├── variant_model.dart
│   │   ├── addon_model.dart
│   │   ├── addon_group_model.dart
│   │   ├── cart_model.dart
│   │   ├── cart_item_model.dart
│   │   ├── order_model.dart
│   │   ├── order_item_model.dart
│   │   ├── wishlist_item_model.dart
│   │   ├── banner_model.dart
│   │   ├── pagination_model.dart
│   │   └── api_response_model.dart
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── category_repository.dart
│   │   ├── product_repository.dart
│   │   ├── cart_repository.dart
│   │   ├── order_repository.dart
│   │   ├── wishlist_repository.dart
│   │   └── banner_repository.dart
│   │
│   └── requests/
│       ├── login_request.dart
│       ├── register_request.dart
│       ├── otp_verify_request.dart
│       ├── add_to_cart_request.dart
│       ├── checkout_request.dart
│       └── update_cart_request.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── category_provider.dart
│   ├── product_provider.dart
│   ├── cart_provider.dart
│   ├── order_provider.dart
│   ├── wishlist_provider.dart
│   ├── banner_provider.dart
│   └── app_provider.dart
│
├── services/
│   ├── api_service.dart             # HTTP client
│   ├── storage_service.dart         # SharedPreferences wrapper
│   └── navigation_service.dart      # Navigation helper
│
├── routes/
│   └── app_routes.dart              # Route management
│
├── screens/
│   └── ... (existing screens)
│
└── widgets/
    └── ... (existing widgets)
```

---

## Configuration Classes

### 1. API Configuration (`lib/config/api_config.dart`)

```dart
class ApiConfig {
  ApiConfig._();

  // Base URL - Change based on environment
  static const String baseUrl = 'https://api.maicafe.com/api';

  // Timeout durations (in milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // API Endpoints
  static const String authPrefix = '/auth';
  static const String login = '$authPrefix/login';
  static const String register = '$authPrefix/register';
  static const String logout = '$authPrefix/logout';
  static const String user = '$authPrefix/user';
  static const String verifyOtp = '$authPrefix/verify-otp';
  static const String resendOtp = '$authPrefix/resend-otp';
  static const String forgotPassword = '$authPrefix/forgot-password';
  static const String resetPassword = '$authPrefix/reset-password';

  // Categories
  static const String categories = '/categories';
  static String category(String slug) => '/categories/$slug';

  // Products
  static const String products = '/products';
  static String product(String slug) => '/products/$slug';

  // Banners
  static const String banners = '/banners';
  static String banner(int id) => '/banners/$id';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String wishlistCount = '/wishlist/count';
  static const String wishlistCheck = '/wishlist/check';
  static const String wishlistToggle = '/wishlist/toggle';
  static const String wishlistClear = '/wishlist/clear';
  static String wishlistCheckProduct(int productId) => '/wishlist/check/$productId';
  static String wishlistRemove(int productId) => '/wishlist/$productId';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String cartCount = '/cart/count';
  static const String cartCoupon = '/cart/coupon';
  static const String cartNotes = '/cart/notes';
  static const String cartClear = '/cart/clear';
  static String cartItem(int itemId) => '/cart/items/$itemId';

  // Orders
  static const String orders = '/orders';
  static const String checkout = '/orders/checkout';
  static const String orderByToken = '/orders/by-token';
  static String order(int id) => '/orders/$id';
  static String orderTrack(int id) => '/orders/$id/track';
  static String orderCancel(int id) => '/orders/$id/cancel';
  static String orderReorder(int id) => '/orders/$id/reorder';
  static String orderPaymentConfirm(int id) => '/orders/$id/payment/confirm';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
```

---

### 2. Storage Keys (`lib/config/storage_keys.dart`)

```dart
class StorageKeys {
  StorageKeys._();

  // Auth
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';

  // Onboarding
  static const String isFirstLaunch = 'is_first_launch';
  static const String hasSeenOnboarding = 'has_seen_onboarding';

  // Cart
  static const String cartId = 'cart_id';
  static const String cartCount = 'cart_count';

  // Settings
  static const String isDarkMode = 'is_dark_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String languageCode = 'language_code';

  // Temp data (for OTP flow)
  static const String pendingEmail = 'pending_email';
  static const String pendingUserId = 'pending_user_id';
}
```

---

### 3. App Configuration (`lib/config/app_config.dart`)

```dart
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'MaiCafe';
  static const String appVersion = '1.0.0';

  // Currency
  static const String currencySymbol = '£';
  static const String currencyCode = 'GBP';

  // Tax
  static const double taxRate = 5.0;

  // Pagination
  static const int defaultPageSize = 15;
  static const int maxPageSize = 100;

  // Rate Limiting
  static const int rateLimitPerMinute = 60;

  // OTP
  static const int otpLength = 4;
  static const int otpResendDelaySeconds = 60;

  // Delivery
  static const double deliveryCharge = 2.50;
}
```

---

## Core Classes

### 1. API Exception (`lib/core/exceptions/api_exception.dart`)

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromResponse(Map<String, dynamic> response, [int? statusCode]) {
    return ApiException(
      message: response['message'] ?? 'An error occurred',
      statusCode: statusCode,
      errors: response['errors'] as Map<String, dynamic>?,
    );
  }

  factory ApiException.networkError() {
    return const ApiException(
      message: 'Network error. Please check your connection.',
      statusCode: null,
    );
  }

  factory ApiException.timeout() {
    return const ApiException(
      message: 'Request timed out. Please try again.',
      statusCode: null,
    );
  }

  factory ApiException.unauthorized() {
    return const ApiException(
      message: 'Session expired. Please login again.',
      statusCode: 401,
    );
  }

  factory ApiException.serverError() {
    return const ApiException(
      message: 'Server error. Please try again later.',
      statusCode: 500,
    );
  }

  String? getFieldError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}
```

---

### 2. Enums (`lib/core/enums/`)

**Order Status (`order_status.dart`):**
```dart
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  ready('ready', 'Ready'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;

  const OrderStatus(this.value, this.label);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}
```

**Payment Method (`payment_method.dart`):**
```dart
enum PaymentMethod {
  payAtCounter('pay_at_counter', 'Pay at Counter'),
  online('online', 'Online Payment'),
  card('card', 'Card'),
  cash('cash', 'Cash');

  final String value;
  final String label;

  const PaymentMethod(this.value, this.label);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.payAtCounter,
    );
  }
}
```

**Payment Status (`payment_status.dart`):**
```dart
enum PaymentStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  refunded('refunded', 'Refunded'),
  failed('failed', 'Failed');

  final String value;
  final String label;

  const PaymentStatus(this.value, this.label);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
```

**Order Type (`order_type.dart`):**
```dart
enum OrderType {
  pickup('pickup', 'Pickup'),
  delivery('delivery', 'Delivery');

  final String value;
  final String label;

  const OrderType(this.value, this.label);

  static OrderType fromString(String value) {
    return OrderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderType.pickup,
    );
  }
}
```

---

## Data Models

### 1. API Response Model (`lib/data/models/api_response_model.dart`)

```dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
    );
  }
}
```

---

### 2. Pagination Model (`lib/data/models/pagination_model.dart`)

```dart
class PaginationModel {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMorePages;

  const PaginationModel({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.hasMorePages = false,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }

  bool get canLoadMore => currentPage < lastPage;
}
```

---

### 3. User Model (`lib/data/models/user_model.dart`)

```dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.isEmailVerified = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      isEmailVerified: json['email_verified_at'] != null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
    );
  }
}
```

---

### 4. Category Model (`lib/data/models/category_model.dart`)

```dart
class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final String? description;
  final int? productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
    this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'],
      description: json['description'],
      productCount: json['product_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'description': description,
    };
  }
}
```

---

### 5. Product Model (`lib/data/models/product_model.dart`)

```dart
import 'category_model.dart';
import 'variant_model.dart';
import 'addon_group_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? image;
  final List<String>? gallery;
  final bool isFeatured;
  final bool isActive;
  final bool hasVariants;
  final CategoryModel? category;
  final String? price;
  final String? comparePrice;
  final String? minPrice;
  final String? maxPrice;
  final String? priceRange;
  final int? stockQuantity;
  final String? sku;
  final List<VariantModel> variants;
  final List<AddonGroupModel>? addonGroups;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    this.image,
    this.gallery,
    this.isFeatured = false,
    this.isActive = true,
    this.hasVariants = false,
    this.category,
    this.price,
    this.comparePrice,
    this.minPrice,
    this.maxPrice,
    this.priceRange,
    this.stockQuantity,
    this.sku,
    this.variants = const [],
    this.addonGroups,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      shortDescription: json['short_description'],
      image: json['image'],
      gallery: json['gallery'] != null
          ? List<String>.from(json['gallery'])
          : null,
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      hasVariants: json['has_variants'] ?? false,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      price: json['price']?.toString(),
      comparePrice: json['compare_price']?.toString(),
      minPrice: json['min_price']?.toString(),
      maxPrice: json['max_price']?.toString(),
      priceRange: json['price_range'],
      stockQuantity: json['stock_quantity'],
      sku: json['sku'],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => VariantModel.fromJson(v))
              .toList()
          : [],
      addonGroups: json['addon_groups'] != null
          ? (json['addon_groups'] as List)
              .map((g) => AddonGroupModel.fromJson(g))
              .toList()
          : null,
    );
  }

  double get displayPrice {
    if (price != null) return double.tryParse(price!) ?? 0;
    if (minPrice != null) return double.tryParse(minPrice!) ?? 0;
    return 0;
  }

  bool get isInStock => (stockQuantity ?? 0) > 0;
}
```

---

### 6. Variant Model (`lib/data/models/variant_model.dart`)

```dart
class VariantModel {
  final int id;
  final String name;
  final String? sku;
  final String price;
  final String? comparePrice;
  final int stockQuantity;

  const VariantModel({
    required this.id,
    required this.name,
    required this.price,
    this.sku,
    this.comparePrice,
    this.stockQuantity = 0,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      sku: json['sku'],
      comparePrice: json['compare_price']?.toString(),
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }

  double get priceValue => double.tryParse(price) ?? 0;

  bool get isInStock => stockQuantity > 0;
}
```

---

### 7. Addon Models (`lib/data/models/addon_model.dart`, `addon_group_model.dart`)

**Addon Model:**
```dart
class AddonModel {
  final int id;
  final String name;
  final String price;
  final int? groupId;

  const AddonModel({
    required this.id,
    required this.name,
    required this.price,
    this.groupId,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      groupId: json['group_id'],
    );
  }

  double get priceValue => double.tryParse(price) ?? 0;
}
```

**Addon Group Model:**
```dart
import 'addon_model.dart';

class AddonGroupModel {
  final int id;
  final String name;
  final String? description;
  final String selectionType; // "single" or "multiple"
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final List<AddonModel> addons;

  const AddonGroupModel({
    required this.id,
    required this.name,
    this.description,
    this.selectionType = 'multiple',
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections,
    this.addons = const [],
  });

  factory AddonGroupModel.fromJson(Map<String, dynamic> json) {
    return AddonGroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      selectionType: json['selection_type'] ?? 'multiple',
      isRequired: json['is_required'] ?? false,
      minSelections: json['min_selections'] ?? 0,
      maxSelections: json['max_selections'],
      addons: json['addons'] != null
          ? (json['addons'] as List)
              .map((a) => AddonModel.fromJson(a))
              .toList()
          : [],
    );
  }

  bool get isSingleSelect => selectionType == 'single';
  bool get isMultiSelect => selectionType == 'multiple';
}
```

---

### 8. Cart Models (`lib/data/models/cart_model.dart`, `cart_item_model.dart`)

**Cart Item Model:**
```dart
import 'addon_model.dart';

class CartItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final List<CartAddonModel> addons;
  final double addonsTotal;
  final double itemTotal;
  final String? specialInstructions;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.addons = const [],
    this.addonsTotal = 0,
    required this.itemTotal,
    this.specialInstructions,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      variantId: json['variant_id'],
      variantName: json['variant_name'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      addons: json['addons'] != null
          ? (json['addons'] as List)
              .map((a) => CartAddonModel.fromJson(a))
              .toList()
          : [],
      addonsTotal: (json['addons_total'] ?? 0).toDouble(),
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      specialInstructions: json['special_instructions'],
    );
  }
}

class CartAddonModel {
  final int id;
  final String name;
  final double price;

  const CartAddonModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CartAddonModel.fromJson(Map<String, dynamic> json) {
    return CartAddonModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
```

**Cart Model:**
```dart
import 'cart_item_model.dart';

class CartModel {
  final int id;
  final int? storeId;
  final List<CartItemModel> items;
  final int itemsCount;
  final String? couponCode;
  final String? notes;
  final CartSummaryModel summary;
  final CurrencyModel currency;

  const CartModel({
    required this.id,
    this.storeId,
    this.items = const [],
    this.itemsCount = 0,
    this.couponCode,
    this.notes,
    required this.summary,
    required this.currency,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] ?? 0,
      storeId: json['store_id'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => CartItemModel.fromJson(i))
              .toList()
          : [],
      itemsCount: json['items_count'] ?? 0,
      couponCode: json['coupon_code'],
      notes: json['notes'],
      summary: CartSummaryModel.fromJson(json['summary'] ?? {}),
      currency: CurrencyModel.fromJson(json['currency'] ?? {}),
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

class CartSummaryModel {
  final double subtotal;
  final double taxRate;
  final double tax;
  final double discount;
  final double grandTotal;

  const CartSummaryModel({
    this.subtotal = 0,
    this.taxRate = 0,
    this.tax = 0,
    this.discount = 0,
    this.grandTotal = 0,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
    );
  }
}

class CurrencyModel {
  final String symbol;
  final String code;

  const CurrencyModel({
    this.symbol = '£',
    this.code = 'GBP',
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      symbol: json['symbol'] ?? '£',
      code: json['code'] ?? 'GBP',
    );
  }
}
```

---

### 9. Order Model (`lib/data/models/order_model.dart`)

```dart
import '../core/enums/order_status.dart';
import '../core/enums/order_type.dart';
import '../core/enums/payment_method.dart';
import '../core/enums/payment_status.dart';

class OrderModel {
  final int id;
  final String orderNumber;
  final int dailyToken;
  final String formattedToken;
  final String tokenDate;
  final OrderStatus status;
  final OrderType orderType;
  final double subtotal;
  final double tax;
  final double deliveryCharge;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? notes;
  final List<OrderItemModel>? items;
  final int? itemsCount;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.dailyToken,
    required this.formattedToken,
    required this.tokenDate,
    required this.status,
    required this.orderType,
    required this.subtotal,
    required this.tax,
    required this.deliveryCharge,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.deliveryAddress,
    this.notes,
    this.items,
    this.itemsCount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      dailyToken: json['daily_token'] ?? 0,
      formattedToken: json['formatted_token'] ?? '',
      tokenDate: json['token_date'] ?? '',
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      orderType: OrderType.fromString(json['order_type'] ?? 'pickup'),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'pay_at_counter'),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => OrderItemModel.fromJson(i))
              .toList()
          : null,
      itemsCount: json['items_count'],
    );
  }

  bool get canCancel => status == OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
}

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final OrderCustomizationsModel? customizations;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.customizations,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      customizations: json['customizations'] != null
          ? OrderCustomizationsModel.fromJson(json['customizations'])
          : null,
    );
  }
}

class OrderCustomizationsModel {
  final List<OrderAddonModel>? addons;
  final OrderVariantModel? variant;
  final String? specialInstructions;

  const OrderCustomizationsModel({
    this.addons,
    this.variant,
    this.specialInstructions,
  });

  factory OrderCustomizationsModel.fromJson(Map<String, dynamic> json) {
    return OrderCustomizationsModel(
      addons: json['addons'] != null
          ? (json['addons'] as List)
              .map((a) => OrderAddonModel.fromJson(a))
              .toList()
          : null,
      variant: json['variant'] != null
          ? OrderVariantModel.fromJson(json['variant'])
          : null,
      specialInstructions: json['special_instructions'],
    );
  }
}

class OrderAddonModel {
  final int? id;
  final String addonName;
  final double price;
  final int? groupId;

  const OrderAddonModel({
    this.id,
    required this.addonName,
    required this.price,
    this.groupId,
  });

  factory OrderAddonModel.fromJson(Map<String, dynamic> json) {
    return OrderAddonModel(
      id: json['addon_id'] ?? json['id'],
      addonName: json['addon_name'] ?? json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      groupId: json['group_id'],
    );
  }
}

class OrderVariantModel {
  final int id;
  final String name;
  final double price;

  const OrderVariantModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory OrderVariantModel.fromJson(Map<String, dynamic> json) {
    return OrderVariantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
```

---

### 10. Wishlist Model (`lib/data/models/wishlist_item_model.dart`)

```dart
import 'product_model.dart';

class WishlistItemModel {
  final int id;
  final DateTime addedAt;
  final ProductModel product;

  const WishlistItemModel({
    required this.id,
    required this.addedAt,
    required this.product,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] ?? 0,
      addedAt: DateTime.parse(json['added_at'] ?? DateTime.now().toIso8601String()),
      product: ProductModel.fromJson(json['product'] ?? {}),
    );
  }
}
```

---

### 11. Banner Model (`lib/data/models/banner_model.dart`)

```dart
class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final String image;
  final String? buttonText;
  final String? buttonLink;

  const BannerModel({
    required this.id,
    required this.title,
    required this.image,
    this.subtitle,
    this.buttonText,
    this.buttonLink,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      subtitle: json['subtitle'],
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
    );
  }
}
```

---

## Request Models

### 1. Login Request (`lib/data/requests/login_request.dart`)

```dart
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
```

---

### 2. Register Request (`lib/data/requests/register_request.dart`)

```dart
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null) 'phone': phone,
    };
  }
}
```

---

### 3. OTP Verify Request (`lib/data/requests/otp_verify_request.dart`)

```dart
class OtpVerifyRequest {
  final String email;
  final String otp;

  const OtpVerifyRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}
```

---

### 4. Add to Cart Request (`lib/data/requests/add_to_cart_request.dart`)

```dart
class AddToCartRequest {
  final int productId;
  final int quantity;
  final int? variantId;
  final List<CartAddonRequest>? addons;
  final String? specialInstructions;

  const AddToCartRequest({
    required this.productId,
    this.quantity = 1,
    this.variantId,
    this.addons,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
      if (addons != null && addons!.isNotEmpty)
        'addons': addons!.map((a) => a.toJson()).toList(),
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
    };
  }
}

class CartAddonRequest {
  final int id;
  final int quantity;

  const CartAddonRequest({
    required this.id,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
    };
  }
}
```

---

### 5. Checkout Request (`lib/data/requests/checkout_request.dart`)

```dart
import '../../core/enums/order_type.dart';
import '../../core/enums/payment_method.dart';

class CheckoutRequest {
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final String? deliveryAddress;
  final String? notes;

  const CheckoutRequest({
    required this.orderType,
    required this.paymentMethod,
    this.deliveryAddress,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_type': orderType.value,
      'payment_method': paymentMethod.value,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (notes != null) 'notes': notes,
    };
  }
}
```

---

## Services

### 1. Storage Service (`lib/services/storage_service.dart`)

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../config/storage_keys.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Auth Token
  Future<void> setAuthToken(String token) async {
    await _preferences?.setString(StorageKeys.authToken, token);
  }

  String? getAuthToken() {
    return _preferences?.getString(StorageKeys.authToken);
  }

  Future<void> removeAuthToken() async {
    await _preferences?.remove(StorageKeys.authToken);
  }

  bool get hasAuthToken => getAuthToken() != null;

  // User Data
  Future<void> setUserData({
    required int id,
    required String name,
    required String email,
  }) async {
    await _preferences?.setInt(StorageKeys.userId, id);
    await _preferences?.setString(StorageKeys.userName, name);
    await _preferences?.setString(StorageKeys.userEmail, email);
    await _preferences?.setBool(StorageKeys.isLoggedIn, true);
  }

  int? getUserId() => _preferences?.getInt(StorageKeys.userId);
  String? getUserName() => _preferences?.getString(StorageKeys.userName);
  String? getUserEmail() => _preferences?.getString(StorageKeys.userEmail);
  bool get isLoggedIn => _preferences?.getBool(StorageKeys.isLoggedIn) ?? false;

  Future<void> clearUserData() async {
    await _preferences?.remove(StorageKeys.userId);
    await _preferences?.remove(StorageKeys.userName);
    await _preferences?.remove(StorageKeys.userEmail);
    await _preferences?.setBool(StorageKeys.isLoggedIn, false);
    await removeAuthToken();
  }

  // Pending Email (for OTP verification)
  Future<void> setPendingEmail(String email) async {
    await _preferences?.setString(StorageKeys.pendingEmail, email);
  }

  String? getPendingEmail() {
    return _preferences?.getString(StorageKeys.pendingEmail);
  }

  Future<void> clearPendingEmail() async {
    await _preferences?.remove(StorageKeys.pendingEmail);
  }

  // Cart Count
  Future<void> setCartCount(int count) async {
    await _preferences?.setInt(StorageKeys.cartCount, count);
  }

  int getCartCount() => _preferences?.getInt(StorageKeys.cartCount) ?? 0;

  // Settings
  Future<void> setDarkMode(bool isDark) async {
    await _preferences?.setBool(StorageKeys.isDarkMode, isDark);
  }

  bool get isDarkMode => _preferences?.getBool(StorageKeys.isDarkMode) ?? false;

  // First Launch
  bool get isFirstLaunch =>
      _preferences?.getBool(StorageKeys.isFirstLaunch) ?? true;

  Future<void> setFirstLaunchComplete() async {
    await _preferences?.setBool(StorageKeys.isFirstLaunch, false);
  }

  // Clear All
  Future<void> clearAll() async {
    await _preferences?.clear();
  }
}
```

---

### 2. API Service (`lib/services/api_service.dart`)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../core/exceptions/api_exception.dart';
import 'storage_service.dart';

class ApiService {
  static ApiService? _instance;
  final StorageService _storageService;

  ApiService._(this._storageService);

  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      final storageService = await StorageService.getInstance();
      _instance = ApiService._(storageService);
    }
    return _instance!;
  }

  // Headers
  Map<String, String> get _headers {
    final token = _storageService.getAuthToken();
    if (token != null) {
      return ApiConfig.authHeaders(token);
    }
    return ApiConfig.defaultHeaders;
  }

  // GET Request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .delete(uri, headers: _headers)
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on http.ClientException {
      throw ApiException.networkError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Handle Response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 401:
        throw ApiException.unauthorized();
      case 422:
        throw ApiException.fromResponse(body, response.statusCode);
      case 404:
        throw ApiException(
          message: body['message'] ?? 'Resource not found',
          statusCode: 404,
        );
      case 409:
        throw ApiException.fromResponse(body, response.statusCode);
      case 429:
        throw ApiException(
          message: 'Too many requests. Please try again later.',
          statusCode: 429,
        );
      case 500:
        throw ApiException.serverError();
      default:
        throw ApiException.fromResponse(body, response.statusCode);
    }
  }
}
```

---

## Repositories

### 1. Auth Repository (`lib/data/repositories/auth_repository.dart`)

```dart
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/user_model.dart';
import '../requests/login_request.dart';
import '../requests/register_request.dart';
import '../requests/otp_verify_request.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Register
  Future<void> register(RegisterRequest request) async {
    final response = await _apiService.post(
      ApiConfig.register,
      body: request.toJson(),
    );

    if (response['success'] == true) {
      // Store email for OTP verification
      await _storageService.setPendingEmail(request.email);
    }
  }

  // Verify OTP
  Future<UserModel> verifyOtp(OtpVerifyRequest request) async {
    final response = await _apiService.post(
      ApiConfig.verifyOtp,
      body: request.toJson(),
    );

    if (response['success'] == true) {
      final data = response['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);

      // Store auth data
      await _storageService.setAuthToken(token);
      await _storageService.setUserData(
        id: user.id,
        name: user.name,
        email: user.email,
      );
      await _storageService.clearPendingEmail();

      return user;
    }

    throw Exception(response['message'] ?? 'OTP verification failed');
  }

  // Resend OTP
  Future<void> resendOtp(String email) async {
    await _apiService.post(
      ApiConfig.resendOtp,
      body: {'email': email},
    );
  }

  // Login
  Future<UserModel> login(LoginRequest request) async {
    final response = await _apiService.post(
      ApiConfig.login,
      body: request.toJson(),
    );

    if (response['success'] == true) {
      final data = response['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);

      // Store auth data
      await _storageService.setAuthToken(token);
      await _storageService.setUserData(
        id: user.id,
        name: user.name,
        email: user.email,
      );

      return user;
    }

    throw Exception(response['message'] ?? 'Login failed');
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logout);
    } finally {
      await _storageService.clearUserData();
    }
  }

  // Get Current User
  Future<UserModel> getCurrentUser() async {
    final response = await _apiService.get(ApiConfig.user);

    if (response['success'] == true) {
      return UserModel.fromJson(response['data']['user']);
    }

    throw Exception(response['message'] ?? 'Failed to get user');
  }

  // Check if logged in
  bool get isLoggedIn => _storageService.isLoggedIn;

  // Get stored user data
  UserModel? getStoredUser() {
    final id = _storageService.getUserId();
    final name = _storageService.getUserName();
    final email = _storageService.getUserEmail();

    if (id != null && name != null && email != null) {
      return UserModel(id: id, name: name, email: email);
    }
    return null;
  }

  // Get pending email for OTP
  String? get pendingEmail => _storageService.getPendingEmail();
}
```

---

### 2. Product Repository (`lib/data/repositories/product_repository.dart`)

```dart
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../models/product_model.dart';
import '../models/pagination_model.dart';

class ProductRepository {
  final ApiService _apiService;

  ProductRepository({required ApiService apiService})
      : _apiService = apiService;

  Future<ProductListResponse> getProducts({
    String? search,
    String? category,
    int? categoryId,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    bool? hasVariants,
    bool? inStock,
    String? sort,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null) 'search': search,
      if (category != null) 'category': category,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (featured != null) 'featured': featured.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (hasVariants != null) 'has_variants': hasVariants.toString(),
      if (inStock != null) 'in_stock': inStock.toString(),
      if (sort != null) 'sort': sort,
    };

    final response = await _apiService.get(
      ApiConfig.products,
      queryParams: queryParams,
    );

    if (response['success'] == true) {
      final data = response['data'];
      return ProductListResponse(
        products: (data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList(),
        pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
      );
    }

    throw Exception(response['message'] ?? 'Failed to load products');
  }

  Future<ProductModel> getProduct(String slug) async {
    final response = await _apiService.get(ApiConfig.product(slug));

    if (response['success'] == true) {
      return ProductModel.fromJson(response['data']['product']);
    }

    throw Exception(response['message'] ?? 'Failed to load product');
  }
}

class ProductListResponse {
  final List<ProductModel> products;
  final PaginationModel pagination;

  const ProductListResponse({
    required this.products,
    required this.pagination,
  });
}
```

---

### 3. Cart Repository (`lib/data/repositories/cart_repository.dart`)

```dart
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../models/cart_model.dart';
import '../requests/add_to_cart_request.dart';

class CartRepository {
  final ApiService _apiService;

  CartRepository({required ApiService apiService})
      : _apiService = apiService;

  Future<CartModel> getCart() async {
    final response = await _apiService.get(ApiConfig.cart);

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to load cart');
  }

  Future<CartModel> addToCart(AddToCartRequest request) async {
    final response = await _apiService.post(
      ApiConfig.cartItems,
      body: request.toJson(),
    );

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to add to cart');
  }

  Future<CartModel> updateItemQuantity(int itemId, int quantity) async {
    final response = await _apiService.put(
      ApiConfig.cartItem(itemId),
      body: {'quantity': quantity},
    );

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to update cart');
  }

  Future<CartModel> removeItem(int itemId) async {
    final response = await _apiService.delete(ApiConfig.cartItem(itemId));

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to remove item');
  }

  Future<int> getCartCount() async {
    final response = await _apiService.get(ApiConfig.cartCount);

    if (response['success'] == true) {
      return response['data']['count'] ?? 0;
    }

    return 0;
  }

  Future<CartModel> applyCoupon(String couponCode) async {
    final response = await _apiService.post(
      ApiConfig.cartCoupon,
      body: {'coupon_code': couponCode},
    );

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to apply coupon');
  }

  Future<CartModel> removeCoupon() async {
    final response = await _apiService.delete(ApiConfig.cartCoupon);

    if (response['success'] == true) {
      return CartModel.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to remove coupon');
  }

  Future<void> clearCart() async {
    await _apiService.delete(ApiConfig.cartClear);
  }
}
```

---

### 4. Order Repository (`lib/data/repositories/order_repository.dart`)

```dart
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../models/order_model.dart';
import '../models/pagination_model.dart';
import '../requests/checkout_request.dart';

class OrderRepository {
  final ApiService _apiService;

  OrderRepository({required ApiService apiService})
      : _apiService = apiService;

  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final response = await _apiService.post(
      ApiConfig.checkout,
      body: request.toJson(),
    );

    if (response['success'] == true) {
      final data = response['data'];
      return CheckoutResponse(
        order: OrderModel.fromJson(data['order']),
        payment: PaymentInfo.fromJson(data['payment']),
      );
    }

    throw Exception(response['message'] ?? 'Checkout failed');
  }

  Future<OrderListResponse> getOrders({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null) 'status': status,
    };

    final response = await _apiService.get(
      ApiConfig.orders,
      queryParams: queryParams,
    );

    if (response['success'] == true) {
      final data = response['data'];
      return OrderListResponse(
        orders: (data['orders'] as List)
            .map((o) => OrderModel.fromJson(o))
            .toList(),
        pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
      );
    }

    throw Exception(response['message'] ?? 'Failed to load orders');
  }

  Future<OrderModel> getOrder(int id) async {
    final response = await _apiService.get(ApiConfig.order(id));

    if (response['success'] == true) {
      return OrderModel.fromJson(response['data']['order']);
    }

    throw Exception(response['message'] ?? 'Failed to load order');
  }

  Future<OrderTrackingInfo> trackOrder(int id) async {
    final response = await _apiService.get(ApiConfig.orderTrack(id));

    if (response['success'] == true) {
      return OrderTrackingInfo.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to track order');
  }

  Future<void> cancelOrder(int id) async {
    final response = await _apiService.post(ApiConfig.orderCancel(id));

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to cancel order');
    }
  }

  Future<ReorderResponse> reorder(int id) async {
    final response = await _apiService.post(ApiConfig.orderReorder(id));

    if (response['success'] == true) {
      return ReorderResponse.fromJson(response['data']);
    }

    throw Exception(response['message'] ?? 'Failed to reorder');
  }
}

class CheckoutResponse {
  final OrderModel order;
  final PaymentInfo payment;

  const CheckoutResponse({
    required this.order,
    required this.payment,
  });
}

class PaymentInfo {
  final bool required;
  final String method;
  final double amount;
  final String currency;
  final String? paymentUrl;
  final String? instructions;

  const PaymentInfo({
    required this.required,
    required this.method,
    required this.amount,
    required this.currency,
    this.paymentUrl,
    this.instructions,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      required: json['required'] ?? false,
      method: json['method'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'GBP',
      paymentUrl: json['payment_url'],
      instructions: json['instructions'],
    );
  }
}

class OrderListResponse {
  final List<OrderModel> orders;
  final PaginationModel pagination;

  const OrderListResponse({
    required this.orders,
    required this.pagination,
  });
}

class OrderTrackingInfo {
  final int orderId;
  final String orderNumber;
  final String token;
  final String currentStatus;
  final String statusLabel;
  final String orderType;
  final String? estimatedTime;
  final List<TimelineItem> timeline;
  final bool isCancelled;

  const OrderTrackingInfo({
    required this.orderId,
    required this.orderNumber,
    required this.token,
    required this.currentStatus,
    required this.statusLabel,
    required this.orderType,
    this.estimatedTime,
    required this.timeline,
    required this.isCancelled,
  });

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> json) {
    return OrderTrackingInfo(
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      token: json['token'] ?? '',
      currentStatus: json['current_status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      orderType: json['order_type'] ?? '',
      estimatedTime: json['estimated_time'],
      timeline: (json['timeline'] as List?)
              ?.map((t) => TimelineItem.fromJson(t))
              .toList() ??
          [],
      isCancelled: json['is_cancelled'] ?? false,
    );
  }
}

class TimelineItem {
  final String label;
  final String icon;
  final bool completed;
  final bool? current;

  const TimelineItem({
    required this.label,
    required this.icon,
    required this.completed,
    this.current,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      completed: json['completed'] ?? false,
      current: json['current'],
    );
  }
}

class ReorderResponse {
  final int addedItems;
  final List<String> skippedItems;

  const ReorderResponse({
    required this.addedItems,
    required this.skippedItems,
  });

  factory ReorderResponse.fromJson(Map<String, dynamic> json) {
    return ReorderResponse(
      addedItems: json['added_items'] ?? 0,
      skippedItems: List<String>.from(json['skipped_items'] ?? []),
    );
  }
}
```

---

## Providers (State Management)

### 1. Auth Provider (`lib/providers/auth_provider.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/requests/login_request.dart';
import '../data/requests/register_request.dart';
import '../data/requests/otp_verify_request.dart';
import '../core/exceptions/api_exception.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error, otpRequired }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _pendingEmail;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _initializeAuth();
  }

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _pendingEmail ?? _authRepository.pendingEmail;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // Initialize
  Future<void> _initializeAuth() async {
    if (_authRepository.isLoggedIn) {
      _user = _authRepository.getStoredUser();
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Register
  Future<bool> register(RegisterRequest request) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(request);
      _pendingEmail = request.email;
      _state = AuthState.otpRequired;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String otp) async {
    if (_pendingEmail == null && _authRepository.pendingEmail == null) {
      _errorMessage = 'No pending verification';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = _pendingEmail ?? _authRepository.pendingEmail!;
      _user = await _authRepository.verifyOtp(
        OtpVerifyRequest(email: email, otp: otp),
      );
      _pendingEmail = null;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.otpRequired;
      notifyListeners();
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp() async {
    final email = _pendingEmail ?? _authRepository.pendingEmail;
    if (email == null) {
      _errorMessage = 'No pending verification';
      return false;
    }

    try {
      await _authRepository.resendOtp(email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // Login
  Future<bool> login(LoginRequest request) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(request);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authRepository.logout();
    } finally {
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  // Clear Error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

### 2. Cart Provider (`lib/providers/cart_provider.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../data/models/cart_model.dart';
import '../data/repositories/cart_repository.dart';
import '../data/requests/add_to_cart_request.dart';
import '../core/exceptions/api_exception.dart';
import '../services/storage_service.dart';

enum CartState { initial, loading, loaded, error }

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository;
  final StorageService _storageService;

  CartState _state = CartState.initial;
  CartModel? _cart;
  String? _errorMessage;
  int _cartCount = 0;

  CartProvider({
    required CartRepository cartRepository,
    required StorageService storageService,
  })  : _cartRepository = cartRepository,
        _storageService = storageService {
    _cartCount = _storageService.getCartCount();
  }

  // Getters
  CartState get state => _state;
  CartModel? get cart => _cart;
  String? get errorMessage => _errorMessage;
  int get cartCount => _cartCount;
  bool get isLoading => _state == CartState.loading;
  bool get isEmpty => _cart?.isEmpty ?? true;

  // Load Cart
  Future<void> loadCart() async {
    _state = CartState.loading;
    notifyListeners();

    try {
      _cart = await _cartRepository.getCart();
      _cartCount = _cart?.itemsCount ?? 0;
      await _storageService.setCartCount(_cartCount);
      _state = CartState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = CartState.error;
    }
    notifyListeners();
  }

  // Add to Cart
  Future<bool> addToCart(AddToCartRequest request) async {
    _state = CartState.loading;
    notifyListeners();

    try {
      _cart = await _cartRepository.addToCart(request);
      _cartCount = _cart?.itemsCount ?? 0;
      await _storageService.setCartCount(_cartCount);
      _state = CartState.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = CartState.error;
      notifyListeners();
      return false;
    }
  }

  // Update Quantity
  Future<bool> updateQuantity(int itemId, int quantity) async {
    try {
      _cart = await _cartRepository.updateItemQuantity(itemId, quantity);
      _cartCount = _cart?.itemsCount ?? 0;
      await _storageService.setCartCount(_cartCount);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // Remove Item
  Future<bool> removeItem(int itemId) async {
    try {
      _cart = await _cartRepository.removeItem(itemId);
      _cartCount = _cart?.itemsCount ?? 0;
      await _storageService.setCartCount(_cartCount);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // Apply Coupon
  Future<bool> applyCoupon(String code) async {
    try {
      _cart = await _cartRepository.applyCoupon(code);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // Remove Coupon
  Future<bool> removeCoupon() async {
    try {
      _cart = await _cartRepository.removeCoupon();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // Clear Cart
  Future<void> clearCart() async {
    try {
      await _cartRepository.clearCart();
      _cart = null;
      _cartCount = 0;
      await _storageService.setCartCount(0);
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
  }

  // Refresh Count
  Future<void> refreshCount() async {
    try {
      _cartCount = await _cartRepository.getCartCount();
      await _storageService.setCartCount(_cartCount);
      notifyListeners();
    } catch (_) {}
  }
}
```

---

## Route Management

### Updated App Routes (`lib/routes/app_routes.dart`)

```dart
import 'package:flutter/material.dart';

// Auth Screens
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';

// Main Screens
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/redeem_coupon_screen.dart';
import '../screens/payment/payment_method_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_details_screen.dart';
import '../screens/orders/order_success_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/address/my_address_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String otpVerification = '/otp-verification';
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
  static const String orderSuccess = '/order-success';
  static const String profile = '/profile';

  // Initial Route
  static const String initialRoute = splash;

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case register:
        return _buildRoute(const RegisterScreen(), settings);

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      case otp:
        return _buildRoute(const OtpScreen(), settings);

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(email: args?['email']),
          settings,
        );

      // Main Routes
      case home:
        return _buildRoute(const HomeScreen(), settings);

      case products:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ProductsScreen(
            categorySlug: args?['category_slug'],
            categoryName: args?['category_name'],
          ),
          settings,
        );

      case productDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          ProductDetailScreen(
            productSlug: args['product_slug'],
            productName: args['product_name'],
          ),
          settings,
        );

      case cart:
        return _buildRoute(const CartScreen(), settings);

      case redeemCoupon:
        return _buildRoute(const RedeemCouponScreen(), settings);

      case paymentMethod:
        return _buildRoute(const PaymentMethodScreen(), settings);

      case myAddress:
        return _buildRoute(const MyAddressScreen(), settings);

      case wishlist:
        return _buildRoute(const WishlistScreen(), settings);

      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      case orders:
        return _buildRoute(const OrdersScreen(), settings);

      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          OrderDetailsScreen(orderId: args['order_id']),
          settings,
        );

      case orderSuccess:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          OrderSuccessScreen(orderId: args['order_id']),
          settings,
        );

      case profile:
        return _buildRoute(const ProfileScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  // Build Route Helper
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget screen,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }

  // Navigation Helpers
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}
```

---

## Main App Setup

### 1. Main Entry (`lib/main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wishlist_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  final storageService = await StorageService.getInstance();
  final apiService = await ApiService.getInstance();

  // Initialize Repositories
  final authRepository = AuthRepository(
    apiService: apiService,
    storageService: storageService,
  );
  final cartRepository = CartRepository(apiService: apiService);
  final productRepository = ProductRepository(apiService: apiService);
  final orderRepository = OrderRepository(apiService: apiService);
  final wishlistRepository = WishlistRepository(apiService: apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(
            cartRepository: cartRepository,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productRepository: productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderRepository: orderRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider(wishlistRepository: wishlistRepository),
        ),
      ],
      child: const MaiCafeApp(),
    ),
  );
}
```

---

### 2. App Widget (`lib/app.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme/app_colors.dart';
import 'config/app_config.dart';
import 'routes/app_routes.dart';

class MaiCafeApp extends StatelessWidget {
  const MaiCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Sora',
        scaffoldBackgroundColor: AppColors.primaryBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textHeading),
          titleTextStyle: TextStyle(
            fontFamily: 'Sora',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
      ),
      initialRoute: AppRoutes.initialRoute,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
```

---

## Authentication Flow

```
┌─────────────┐
│   Splash    │
│   Screen    │
└──────┬──────┘
       │
       ▼
  ┌─────────────┐
  │ Check Auth  │
  │   Status    │
  └──────┬──────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌──────┐  ┌──────┐
│Login │  │ Home │ (if authenticated)
│Screen│  │Screen│
└──┬───┘  └──────┘
   │
   ├─────────────────┐
   │                 │
   ▼                 ▼
┌────────┐     ┌──────────┐
│Register│     │  Forgot  │
│ Screen │     │ Password │
└───┬────┘     └──────────┘
    │
    ▼ (on success)
┌─────────────────┐
│  OTP Screen     │
│(Enter Email/Show│
│  confirmation)  │
└────────┬────────┘
         │
         ▼
┌──────────────────┐
│OTP Verification  │
│(Enter 4-digit OTP│
│ received in email│
└────────┬─────────┘
         │
         ▼ (on success)
    ┌──────┐
    │ Home │
    │Screen│
    └──────┘
```

---

## Implementation Priority

### Phase 1: Foundation
1. Set up folder structure
2. Create configuration classes
3. Create core classes (exceptions, enums)
4. Implement StorageService
5. Implement ApiService

### Phase 2: Authentication
6. Create User model
7. Create Auth request models
8. Implement AuthRepository
9. Implement AuthProvider
10. Update auth screens to use Provider

### Phase 3: Products & Categories
11. Create Product, Category, Variant, Addon models
12. Implement ProductRepository, CategoryRepository
13. Implement ProductProvider, CategoryProvider
14. Update Home, Products screens

### Phase 4: Cart
15. Create Cart models
16. Create Cart request models
17. Implement CartRepository
18. Implement CartProvider
19. Update Cart screen

### Phase 5: Wishlist
20. Create Wishlist model
21. Implement WishlistRepository
22. Implement WishlistProvider
23. Update Wishlist screen

### Phase 6: Orders
24. Create Order models
25. Create Checkout request
26. Implement OrderRepository
27. Implement OrderProvider
28. Update Payment, Orders screens

### Phase 7: Final Integration
29. Banners integration
30. Error handling improvements
31. Loading states
32. Pull to refresh
33. Pagination
34. Testing

---

## Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # HTTP Client
  http: ^1.1.0

  # Local Storage
  shared_preferences: ^2.2.2

  # Other existing dependencies
  cupertino_icons: ^1.0.8
  shimmer: ^3.0.0
```

---

## Summary

This implementation plan provides:

1. **No Hardcoding** - All configuration in dedicated classes
2. **Provider State Management** - Clean separation of UI and business logic
3. **SharedPreferences** - For token and user data storage
4. **OTP Flow** - Register → OTP Verification → Home
5. **Route Management** - Using `onGenerateRoute` with `AppRoutes` class
6. **Repository Pattern** - Clean data layer abstraction
7. **Error Handling** - Centralized exception handling
8. **Type Safety** - Models for all API responses
