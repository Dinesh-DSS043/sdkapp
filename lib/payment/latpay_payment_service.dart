class LatpayPaymentService {
  static Future<Map<String, dynamic>> secure3DPayment({
    required Map<String, dynamic> payload,
  }) async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock success response
    return {
      "statuscode": "0",
      "statusdesc": "Payment Successful",
      "transactionid": "LPS123456789",
    };
  }
}