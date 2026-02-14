typedef LatpayPaymentCompleted = void Function(Map<String, dynamic> response);

class LatpayPaymentCallback {
  static LatpayPaymentCompleted? onPaymentCompleted;
}