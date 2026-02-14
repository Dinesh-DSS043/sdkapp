import 'package:flutter/material.dart';

class LatpayErrorDialog {
  static Future<void> show(
    BuildContext context,
    String message,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Payment Error"),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Navigator.pop(context); // exit payment flow
            },
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }
}