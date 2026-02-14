class LatpayService {
  static Future<Map<String, dynamic>> fetchFinal3DSResult({
    required String reference,
  }) async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(seconds: 1));

    // Example mocked success
    return {
      "Capture": {
        "responsekey": "latpaytest123",
        "amount": "0.01",
        "reference": reference,
        "description": reference,
        "currency": "EUR",
        "status": {
          "errorcode": "00",
          "errordesc": "Transaction Approved"
        }
      }
    };
  }
}