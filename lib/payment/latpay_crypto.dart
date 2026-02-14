import 'dart:convert';
import 'package:crypto/crypto.dart';

class LatpayCrypto {
  static String generateTransKey3DSecure({
    required String currency,
    required String amount,
    required String reference,
    required String is3dcheck,
    required String dataKey,
  }) {
    final raw = currency + amount + reference + is3dcheck + dataKey;
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }
}