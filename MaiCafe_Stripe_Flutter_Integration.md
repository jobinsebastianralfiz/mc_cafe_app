# MaiCafe — Stripe Payment Integration Guide for Flutter

**Date:** 2026-06-06  
**Backend:** Laravel API (dev.maicafeuk.com)  
**Payment Gateway:** Stripe  

---

## Overview

The payment flow works as follows:

```
Flutter App                    MaiCafe API                   Stripe
     |                              |                            |
     |-- POST /orders/checkout ---> |                            |
     |<-- order_id, status:pending  |                            |
     |                              |                            |
     |-- POST /orders/{id}/         |                            |
     |   payment/initiate --------> |                            |
     |                              |-- createPaymentIntent ---> |
     |                              |<-- client_secret ----------|
     |<-- client_secret, intent_id  |                            |
     |                              |                            |
     |-- confirmPayment(            |                            |
     |   client_secret,             |                            |
     |   card details) -------------|---------(Stripe SDK)-----> |
     |                              |                            |
     |<-- Payment Result            |<-- Webhook: succeeded -----|
     |                              |    (order marked paid)     |
     |-- GET /orders/{id} --------> |                            |
     |<-- status: confirmed         |                            |
```

---

## 1. Add Dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  flutter_stripe: ^10.0.0
  http: ^1.2.0
  dio: ^5.4.0          # or use http — whichever you already use
```

Run:
```bash
flutter pub get
```

---

## 2. Initialize Stripe

In `main.dart`, initialize Stripe before `runApp()`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
  // For live: Stripe.publishableKey = 'pk_live_YOUR_PUBLISHABLE_KEY';

  await Stripe.instance.applySettings();

  runApp(const MyApp());
}
```

---

## 3. Android Setup

In `android/app/build.gradle`, set minimum SDK to 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

---

## 4. iOS Setup

In `ios/Podfile`, set platform to iOS 13:

```ruby
platform :ios, '13.0'
```

---

## 5. API Endpoints Reference

### Base URL
```
https://dev.maicafeuk.com/api
```

### Authentication
All payment endpoints require the user's Bearer token in the header:
```
Authorization: Bearer USER_TOKEN
Content-Type: application/json
```

---

### 5.1 Create Order

**POST** `/orders/checkout`

**Request Body:**
```json
{
  "payment_method": "online",
  "order_type": "pickup"
}
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": 15,
      "order_number": "ORD-QKGUKRPW",
      "total": "18.44",
      "status": "pending",
      "payment_status": "pending",
      "payment_method": "online"
    }
  }
}
```

Save the `order.id` — you need it for the next step.

---

### 5.2 Initiate Payment

**POST** `/orders/{id}/payment/initiate`

No request body needed.

**Success Response:**
```json
{
  "success": true,
  "client_secret": "pi_3TfLfxCi0EWFYoEB0rpF8Zrq_secret_xxxxx",
  "payment_intent_id": "pi_3TfLfxCi0EWFYoEB0rpF8Zrq"
}
```

**Error Responses:**

| HTTP | Meaning |
|------|---------|
| 404 | Order not found or doesn't belong to user |
| 422 | Order not eligible (already paid, wrong payment method) |
| 500 | Stripe service unavailable |

---

### 5.3 Get Order Status

**GET** `/orders/{id}`

**Success Response:**
```json
{
  "id": 15,
  "status": "confirmed",
  "payment_status": "paid",
  "payment_reference": "pi_3TfLfxCi0EWFYoEB0rpF8Zrq"
}
```

---

## 6. Flutter Payment Implementation

### 6.1 Payment Service Class

Create `lib/services/payment_service.dart`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

class PaymentService {
  final Dio _dio;

  PaymentService(this._dio);

  /// Step 1: Call backend to create PaymentIntent
  Future<Map<String, dynamic>> initiatePayment(int orderId) async {
    final response = await _dio.post(
      '/orders/$orderId/payment/initiate',
    );

    if (response.data['success'] == true) {
      return {
        'client_secret': response.data['client_secret'],
        'payment_intent_id': response.data['payment_intent_id'],
      };
    }

    throw Exception(response.data['message'] ?? 'Failed to initiate payment');
  }

  /// Step 2: Present Stripe payment sheet and confirm
  Future<void> processPayment({
    required int orderId,
    required String customerName,
    required String customerEmail,
  }) async {
    // Get client_secret from backend
    final paymentData = await initiatePayment(orderId);
    final clientSecret = paymentData['client_secret'];

    // Initialize the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'MaiCafe',
        style: ThemeMode.system,
        billingDetails: BillingDetails(
          name: customerName,
          email: customerEmail,
        ),
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
          name: CollectionMode.automatic,
          email: CollectionMode.automatic,
        ),
      ),
    );

    // Present the payment sheet to the user
    await Stripe.instance.presentPaymentSheet();
    // If no exception thrown, payment was successful
  }
}
```

---

### 6.2 Payment Screen

Create `lib/screens/payment_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double orderTotal;
  final String customerName;
  final String customerEmail;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.orderTotal,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      final paymentService = PaymentService(dio); // your dio instance

      await paymentService.processPayment(
        orderId: widget.orderId,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
      );

      // Payment successful — navigate to success screen
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: {'order_id': widget.orderId},
        );
      }
    } on StripeException catch (e) {
      // User cancelled or card declined
      _showError(e.error.localizedMessage ?? 'Payment cancelled');
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '£${widget.orderTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Pay button
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Pay £${widget.orderTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 6.3 Order Success Screen

After payment, poll or navigate to confirm the order:

```dart
Future<void> _checkOrderStatus(int orderId) async {
  final response = await _dio.get('/orders/$orderId');
  final order = response.data;

  if (order['payment_status'] == 'paid' && order['status'] == 'confirmed') {
    // Show success UI
  } else {
    // Payment processing — show spinner and retry after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    await _checkOrderStatus(orderId);
  }
}
```

---

## 7. Payment Flow — Step by Step Summary

```
1. User places order
      POST /api/orders/checkout
      { "payment_method": "online", "order_type": "pickup" }
      → Save returned order_id

2. Navigate to PaymentScreen with order_id and total

3. User taps "Pay"
      POST /api/orders/{id}/payment/initiate
      → Get client_secret

4. Stripe payment sheet opens automatically
      → User enters card details
      → Stripe handles 3DS if required

5. On success → navigate to Order Success screen

6. Backend webhook confirms order automatically
      payment_status → "paid"
      status → "confirmed"

7. GET /api/orders/{id} to show confirmed order details
```

---

## 8. Error Handling

| Error | Cause | Handle |
|-------|-------|--------|
| `StripeException` with cancel | User dismissed sheet | Show "Payment cancelled" toast |
| `StripeException` card declined | Invalid card | Show Stripe's `localizedMessage` |
| API 404 | Wrong order ID or token expired | Re-login user |
| API 422 | Order already paid or wrong payment method | Show message, refresh order |
| API 500 | Stripe service down | Show "Try again later" |

---

## 9. Test Cards

Use these during development (test mode only):

| Card Number | Scenario |
|-------------|----------|
| `4242 4242 4242 4242` | Payment succeeds |
| `4000 0000 0000 0002` | Card declined |
| `4000 0025 0000 3155` | Requires 3DS authentication |
| `4000 0000 0000 9995` | Insufficient funds |

Use any future expiry date, any 3-digit CVC, any postcode.

---

## 10. Going Live Checklist

- [ ] Replace `pk_test_` with `pk_live_` in `main.dart`
- [ ] Confirm backend `.env` has `sk_live_` and `whsec_` (live webhook secret)
- [ ] Stripe webhook endpoint registered for live mode:
      `https://dev.maicafeuk.com/api/webhooks/stripe`
- [ ] Test with a real card in small amount before full launch
- [ ] Set `APP_DEBUG=false` on the server

---

## 11. Contact

For backend API questions contact the backend developer.  
For Stripe Dashboard access (API keys, webhook secrets) contact the project owner.
