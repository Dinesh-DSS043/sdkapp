typedef LatpayPaymentAction = void Function(Map<String, dynamic> result);

class LatpayPaymentActionCallback {
  static LatpayPaymentAction? onPaymentAction;
}