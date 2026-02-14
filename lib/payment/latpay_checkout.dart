import 'package:flutter/material.dart';
import 'latpay_api.dart';
import 'paymentsheet.dart';
import 'latpay_error_dialog.dart';
import 'latpay_status.dart';
import 'latpay_payment_callback.dart';
import 'latpay_payment_action_callback.dart';

typedef LatpayStatusCallback = void Function(Map<String, String> status);

// typedef LatpayStatusCallback = void Function(String status);

class LatpayCheckout {
  static Future<void> open({
    required BuildContext context,
    required String merchantUserId,
    required String publicKey,
    required String dataKey,
    required String amount,
    required String currency,
    required String reference,
    required String description,
    required bool is3DEnabled,
    required LatpayStatusCallback onStatus,
    required LatpayPaymentCompleted onPaymentCompleted,
    // required LatpayPaymentAction onPaymentAction,
  }) async {
    /// 1. Fields Validation
    if (merchantUserId.isEmpty ||
        publicKey.isEmpty ||
        amount.isEmpty ||
        currency.isEmpty ||
        reference.isEmpty) {
      final status = LatpayStatus.error(
        errorCode: "9001",
        errorDesc:
            "Invalid payment configuration. Please contact the merchant.",
      );
      // onStatus("errorcode_9001");
      onStatus(status);
      await LatpayErrorDialog.show(
        context,
        "Invalid payment configuration. Please contact the merchant.",
      );
      return;
    }

    /// 2. Calling Key Validation API
    try {
      final response = await LatpayApi.validateKey(
        merchantId: merchantUserId,
        publicKey: publicKey,
        currency: currency,
        amount: amount,
      );

      final errorCode = response["status"]?["errorcode"];

      /// 3. errorCode Validation
      if (errorCode == "00" ||
          errorCode == "6007" ||
          errorCode == "6008" ||
          errorCode == "6009") {
        onStatus(
          LatpayStatus.success(description: "Key validation successful"),
        );

        /// 4️. Opening Payment Sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PaymentSheet(
              amount: double.parse(amount),
              currency: currency,
              cardToken: "",
              merchantId: merchantUserId,
              publicKey: publicKey,
              dataKey: dataKey,
              reference: reference,
              description: description,
              is3DSEnabled: is3DEnabled,
            ),
          ),
        );
      } else {
        final status = LatpayStatus.error(
          errorCode: errorCode ?? "9999",
          errorDesc: "Unable to start payment. Please try again later.",
        );
        onStatus(status);
        await LatpayErrorDialog.show(
          context,
          "Unable to start payment. Please try again later.",
        );
      }
    } catch (e) {
      final status = LatpayStatus.error(
        errorCode: "network_error",
        errorDesc: "Network error occurred. Please check your connection.",
      );
      onStatus(status);
      await LatpayErrorDialog.show(
        context,
        "Network error occurred. Please check your connection.",
      );
    }

    /// 5. OnPaymentCompleted Callback
    LatpayPaymentCallback.onPaymentCompleted = onPaymentCompleted;

    // LatpayPaymentActionCallback.onPaymentAction = onPaymentAction;
  }
}
