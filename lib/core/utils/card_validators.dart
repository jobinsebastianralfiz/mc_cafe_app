/// Card brand detected from the card number prefix.
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

/// Card validation utilities for client-side validation before tokenization.
class CardValidators {
  CardValidators._();

  /// Validate a card number using the Luhn algorithm.
  static bool isValidCardNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 13 || digits.length > 19) return false;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
    return _luhnCheck(digits);
  }

  /// Luhn algorithm implementation.
  static bool _luhnCheck(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Validate expiry in MM/YY format.
  static bool isValidExpiry(String expiry) {
    final cleaned = expiry.replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(cleaned);
    if (match == null) return false;

    final month = int.parse(match.group(1)!);
    final year = int.parse(match.group(2)!) + 2000;

    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final expDate = DateTime(year, month + 1, 0); // last day of exp month
    return expDate.isAfter(now);
  }

  /// Parse expiry string into month and year components.
  /// Returns null if invalid.
  static ({String month, String year})? parseExpiry(String expiry) {
    final cleaned = expiry.replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(cleaned);
    if (match == null) return null;

    final month = match.group(1)!;
    final yearShort = match.group(2)!;
    final year = '20$yearShort';

    return (month: month, year: year);
  }

  /// Validate CVC (3 digits for most cards, 4 for Amex).
  static bool isValidCvc(String cvc, {CardBrand brand = CardBrand.unknown}) {
    final cleaned = cvc.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    final expectedLength = brand == CardBrand.amex ? 4 : 3;
    return cleaned.length == expectedLength;
  }

  /// Detect card brand from the card number prefix.
  static CardBrand detectBrand(String number) {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return CardBrand.unknown;

    // Visa: starts with 4
    if (digits.startsWith('4')) return CardBrand.visa;

    // Mastercard: starts with 51-55 or 2221-2720
    if (digits.length >= 2) {
      final first2 = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (first2 >= 51 && first2 <= 55) return CardBrand.mastercard;
    }
    if (digits.length >= 4) {
      final first4 = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (first4 >= 2221 && first4 <= 2720) return CardBrand.mastercard;
    }

    // Amex: starts with 34 or 37
    if (digits.length >= 2) {
      final prefix = digits.substring(0, 2);
      if (prefix == '34' || prefix == '37') return CardBrand.amex;
    }

    // Discover: starts with 6011, 65, 644-649
    if (digits.length >= 4 && digits.startsWith('6011')) {
      return CardBrand.discover;
    }
    if (digits.length >= 2 && digits.startsWith('65')) {
      return CardBrand.discover;
    }
    if (digits.length >= 3) {
      final first3 = int.tryParse(digits.substring(0, 3)) ?? 0;
      if (first3 >= 644 && first3 <= 649) return CardBrand.discover;
    }

    return CardBrand.unknown;
  }

  /// Get the expected card number length for a brand.
  static int maxCardLength(CardBrand brand) {
    switch (brand) {
      case CardBrand.amex:
        return 15;
      case CardBrand.visa:
      case CardBrand.mastercard:
      case CardBrand.discover:
      case CardBrand.unknown:
        return 16;
    }
  }

  /// Get the display name for a card brand.
  static String brandDisplayName(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.unknown:
        return '';
    }
  }
}
