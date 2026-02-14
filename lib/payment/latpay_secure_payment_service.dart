import 'dart:convert';
import 'package:http/http.dart' as http;

class LatpaySecurePaymentService {
  static const String baseUrl = "https://lateralpayments.com/checkout-staging/";

  static Future<Map<String, dynamic>> process({
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}authorise/SecurePayment"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception("Secure payment API failed");
    }
    print("Output is: ${response.body}");
    return jsonDecode(response.body);
  }
}