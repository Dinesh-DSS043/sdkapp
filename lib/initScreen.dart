import 'dart:convert';
import 'package:flutter/material.dart';
import 'payment/latpay_checkout.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  /// Controllers
  // final _merchantIdCtrl = TextEditingController();
  final _merchantIdCtrl = TextEditingController(text: "test_tbVT_3d");
  final _publicKeyCtrl = TextEditingController(text: "test");
  final _dataKeyCtrl = TextEditingController(text: "test");
  final _referenceCtrl = TextEditingController(text: "lpstest123");
  final _descriptionCtrl = TextEditingController(text: "lpstest123");
  final _currencyCtrl = TextEditingController(text: "EUR");
  final _amountCtrl = TextEditingController(text: "0.01");

  bool _is3DEnabled = false;

  /// Log
  String _paymentLog = "Waiting for payment...\n";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Latpay EComm SDK APP")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// INPUTS
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _input("Merchant ID", _merchantIdCtrl),
                    _input("Public Key", _publicKeyCtrl),
                    _input("Data Key", _dataKeyCtrl),
                    _input("Reference", _referenceCtrl),
                    _input("Description", _descriptionCtrl),
                    _input("Currency", _currencyCtrl),
                    _input("Amount", _amountCtrl,
                        keyboard: TextInputType.number),

                    const SizedBox(height: 8),

                    /// 3DS TOGGLE
                    SwitchListTile(
                      title: const Text("Enable 3D Secure"),
                      value: _is3DEnabled,
                      onChanged: (v) {
                        setState(() => _is3DEnabled = v);
                      },
                    ),

                    const SizedBox(height: 10),

                    /// PAY BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startPayment,
                        child: const Text("Pay Now"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// LOG TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SDK Log",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),

            /// LOG BOX (fills rest of screen)
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _paymentLog,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TextField helper
  Widget _input(
      String label,
      TextEditingController controller, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// START PAYMENT
  void _startPayment() {
    setState(() {
      _paymentLog = "Opening payment sheet...\n";
    });

    LatpayCheckout.open(
      context: context,
      merchantUserId: _merchantIdCtrl.text.trim(),
      publicKey: _publicKeyCtrl.text.trim(),
      dataKey: _dataKeyCtrl.text.trim(),
      amount: _amountCtrl.text.trim(),
      currency: _currencyCtrl.text.trim(),
      reference: _referenceCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      is3DEnabled: _is3DEnabled,

      /// open_card status
      onStatus: (status) {
        setState(() {
          _paymentLog +=
          "\n[STATUS]\n${const JsonEncoder.withIndent('  ').convert(status)}\n";
        });
      },

      /// processing / validation state
      // onPaymentAction: (action) {
      //   setState(() {
      //     _paymentLog +=
      //         "\n[ACTION]\n${const JsonEncoder.withIndent('  ').convert(action)}\n";
      //   });
      // },

      /// final payment result
      onPaymentCompleted: (response) {
        setState(() {
          _paymentLog +=
          "\n[COMPLETED]\n${const JsonEncoder.withIndent('  ').convert(response)}\n";
        });
      },
    );
  }
}