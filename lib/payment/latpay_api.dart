import 'dart:convert';
import 'package:http/http.dart' as http;

class LatpayApi {
  // static const String baseUrl = "https://lateralpayments.com/checkout-staging/";
  static const String baseUrl = "https://lateralpayments.com/checkout/";

  static Future<Map<String, dynamic>> validateKey({
    required String merchantId,
    required String publicKey,
    required String currency,
    required String amount,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}authorisewallet/Keyvalidation_wallet"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "merchantuserid": merchantId,
        "publickey": publicKey,
        "currency": currency,
        "amount": amount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("API Error");
    }

    return jsonDecode(response.body);
  }
}