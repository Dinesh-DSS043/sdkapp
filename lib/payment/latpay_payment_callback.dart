typedef LatpayPaymentAction = void Function(Map<String, dynamic> result);

class LatpayPaymentActionCallback {
  static LatpayPaymentAction? onPaymentAction;
}

typedef LatpayPaymentCompleted = void Function(Map<String, dynamic> response);

class LatpayPaymentCallback {
  static LatpayPaymentCompleted? onPaymentCompleted;
}