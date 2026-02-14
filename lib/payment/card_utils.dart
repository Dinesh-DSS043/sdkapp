enum CardBrand { visa, mastercard, amex, unknown }

bool isValidCardNumber(String input) {
  final digits = input.replaceAll(' ', '');
  if (digits.length < 13) return false;

  int sum = 0;
  bool alt = false;

  for (int i = digits.length - 1; i >= 0; i--) {
    int n = int.parse(digits[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

bool isValidExpiry(String value) {
  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return false;

  final parts = value.split('/');
  final month = int.parse(parts[0]);
  final year = int.parse(parts[1]) + 2000;

  if (month < 1 || month > 12) return false;

  final now = DateTime.now();
  final expiry = DateTime(year, month + 1, 0);

  return expiry.isAfter(now);
}

CardBrand detectCardBrand(String input) {
  final n = input.replaceAll(' ', '');

  if (n.startsWith('4')) return CardBrand.visa;
  if (RegExp(r'^(51|52|53|54|55)').hasMatch(n)) {
    return CardBrand.mastercard;
  }
  if (RegExp(r'^(34|37)').hasMatch(n)) return CardBrand.amex;

  return CardBrand.unknown;
}

String getCardBrandAsset(CardBrand brand) {
  switch (brand) {
    case CardBrand.visa:
      return "lib/payment/assets/visa.svg";
    case CardBrand.mastercard:
      return "lib/payment/assets/mastercard.svg";
    case CardBrand.amex:
      return "lib/payment/assets/amex.svg";
    default:
      return "";
  }
}