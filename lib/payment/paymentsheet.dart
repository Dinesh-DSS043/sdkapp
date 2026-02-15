import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sdkapp/payment/latpay_3ds_screen.dart';

import 'input_formatters.dart';
import 'card_utils.dart';

import 'latpay_crypto.dart';
import 'latpay_payment_callback.dart';

import 'latpay_secure_payment_service.dart';

class PaymentSheet extends StatefulWidget {
  final double amount;
  final String currency;
  final String cardToken;
  final String merchantId;
  final String publicKey;
  final String dataKey;
  final String reference;
  final String description;
  final bool is3DSEnabled;

  const PaymentSheet({
    super.key,
    required this.amount,
    required this.currency,
    required this.cardToken,
    required this.merchantId,
    required this.publicKey,
    required this.dataKey,
    required this.reference,
    required this.description,
    required this.is3DSEnabled,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _nameCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _cardFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();

  CardBrand _brand = CardBrand.unknown;
  bool saveCard = false;

  String? nameError, cardError, expiryError, cvvError;

  PaymentUIState _paymentState = PaymentUIState.idle;
  String _paymentMessage = "Processing payment...";

  bool _hideKeyboardBarManually = false;
  static const double _keyboardDoneBarHeight = 60;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // _buildBody(context),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    Platform.isIOS &&
                        MediaQuery.of(context).viewInsets.bottom > 0
                    ? _keyboardDoneBarHeight
                    : 0,
              ),
              child: _buildBody(context),
            ),

            /// Payment processing overlay
            if (_paymentState != PaymentUIState.idle)
              Container(
                color: Colors.black.withOpacity(0.45),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildPaymentIcon(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _paymentMessage,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            /// iOS keyboard Done bar
            _buildKeyboardDoneBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// TOTAL AMOUNT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// LEFT: LABEL
                Row(
                  children: const [
                    Icon(
                      Icons.receipt_long,
                      size: 22,
                      color: Color.fromRGBO(37, 51, 113, 1),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Total Payable",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                /// RIGHT: AMOUNT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${widget.currency.toUpperCase()} ${widget.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color.fromRGBO(37, 51, 113, 1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // const Text(
                    //   "Includes all taxes",
                    //   style: TextStyle(fontSize: 12, color: Colors.grey),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "---------- Fast Checkout ----------",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          /// FAST CHECKOUT BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {},
              child: Text(
                "Pay with ${widget.cardToken}",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "---------- Or Pay with Card ----------",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          /// CARD ENTRY SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                /// CARD HOLDER NAME
                TextField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => nameError = null),
                  decoration: InputDecoration(
                    labelText: "Card Holder Name",
                    errorText: nameError,
                    suffixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                /// CARD NUMBER
                TextField(
                  controller: _cardCtrl,
                  focusNode: _cardFocus,
                  keyboardType: TextInputType.number,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CardNumberFormatter(),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _brand = detectCardBrand(v);
                      cardError = null;
                    });
                    if (v.replaceAll(' ', '').length >= 16) {
                      FocusScope.of(context).requestFocus(_expiryFocus);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Card Number",
                    errorText: cardError,
                    suffixIcon: _brand == CardBrand.unknown
                        ? const Icon(Icons.credit_card)
                        : Padding(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              getCardBrandAsset(_brand),
                              width: 24,
                            ),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    /// EXPIRY
                    Expanded(
                      child: TextField(
                        controller: _expiryCtrl,
                        focusNode: _expiryFocus,
                        keyboardType: TextInputType.number,
                        enableInteractiveSelection: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ExpiryDateFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: "MM/YY",
                          errorText: expiryError,
                          suffixIcon: const Icon(Icons.date_range),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// CVV
                    Expanded(
                      child: TextField(
                        controller: _cvvCtrl,
                        focusNode: _cvvFocus,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        enableInteractiveSelection: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: "CVV",
                          counterText: "",
                          errorText: cvvError,
                          suffixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Checkbox(
                      value: saveCard,
                      onChanged: (v) => setState(() => saveCard = v!),
                    ),
                    const Text("Save this Card for Future Payments"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              /// CANCEL BUTTON
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Cancel"),
                  style: OutlinedButton.styleFrom(
                    //foregroundColor: Colors.grey.shade700,
                    //side: BorderSide(color: Colors.grey.shade400),
                    foregroundColor: Color.fromRGBO(250, 73, 79, 1),
                    side: BorderSide(color: Color.fromRGBO(250, 73, 79, 1)),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // onPressed: () => Navigator.pop(context),
                  onPressed: _confirmCancelPayment,
                ),
              ),

              const SizedBox(width: 10),

              /// PAY NOW BUTTON
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.payment,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Pay Now",
                    style: TextStyle(color: Colors.white),
                  ),
                  // label: Text(
                  //   "Pay ${widget.currency.toUpperCase()} ${widget.amount.toStringAsFixed(2)}",
                  //   style: const TextStyle(color: Colors.white),
                  // ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(
                      37,
                      51,
                      113,
                      1,
                    ), // Trust blue
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  //onPressed: isFormValid ? _onPayNow : null
                  onPressed: _onPayNow,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                "Secure and Encrypted Payment System. Powered by Latpay",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon() {
    switch (_paymentState) {
      case PaymentUIState.processing:
        return const SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        );

      case PaymentUIState.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);

      case PaymentUIState.failure:
        return const Icon(Icons.error, color: Colors.red, size: 30);

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onPayNow() async {
    setState(() {
      nameError = cardError = expiryError = cvvError = null;
    });

    /// Card holder name validation
    final nameParts = _nameCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty);

    if (nameParts.length < 2) {
      setState(() => nameError = "Enter first and last name");
      return;
    }

    if (!isValidCardNumber(_cardCtrl.text)) {
      setState(() => cardError = "Invalid card number");
      return;
    }

    if (!isValidExpiry(_expiryCtrl.text)) {
      setState(() => expiryError = "Invalid expiry date");
      return;
    }

    if (_cvvCtrl.text.length < 3) {
      setState(() => cvvError = "Invalid CVV");
      return;
    }

    // if (widget.is3DSEnabled) {
    //   _show3DSDialog();
    //   return;
    // }

    await _processPayment();
  }

  Future<void> _processPayment() async {
    try {
      /// Notifying Merchant: processing started
      // LatpayPaymentActionCallback.onPaymentAction?.call({
      LatpayPaymentCallback.onPaymentCompleted?.call({
        "type": "card",
        "status": {
          "responsetype": "1",
          "statuscode": "0",
          "statusdesc": "Card payment processing...",
          "errorcode": "",
          "errordesc": "",
        },
      });

      /// Showing processing popup
      setState(() {
        _paymentState = PaymentUIState.processing;
        _paymentMessage = "Processing payment...";
      });

      /// Generating 3DS transaction key
      final transKey = LatpayCrypto.generateTransKey3DSecure(
        currency: widget.currency,
        amount: widget.amount.toStringAsFixed(2),
        reference: widget.reference,
        is3dcheck: widget.is3DSEnabled ? 'Y' : 'N',
        dataKey: widget.dataKey,
      );

      print("The Transkey Combination are: ${transKey}");

      final nameParts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.first;
      final lastName = nameParts.sublist(1).join(" ");

      /// Building SecurePayment payload
      final payload = {
        "merchantid": widget.merchantId,
        "publickey": widget.publicKey,
        "transactionkey": transKey,
        "amount": widget.amount.toStringAsFixed(2),
        "currency": widget.currency,
        "reference": widget.reference,
        "description": widget.description,
        "billfirstname": firstName,
        "billlastname": lastName,
        "cardno": _cardCtrl.text.replaceAll(' ', ''),
        "expmonth": _expiryCtrl.text.split('/')[0],
        "expyear": "20${_expiryCtrl.text.split('/')[1]}",
        "cvcno": _cvvCtrl.text,
        "cardtype": _brand.name.toUpperCase(),
        "firstname": "NA",
        "lastname": "NA",
        "email": "hps@lpsmail.com",
        "_3dcheck": widget.is3DSEnabled ? 'Y' : 'N',
      };

      print("3DSecure Payload is: ${payload}");

      /// Call SecurePayment API
      final data = await LatpaySecurePaymentService.process(payload: payload);

      /// 3DS FLOW IF EXIST
      if (data["VBVURL"] != null) {
        final threeDSResult = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => Latpay3DSecureScreen(threeDSData: data),
          ),
        );

        if (threeDSResult == null) {
          throw Exception("3DS cancelled or failed");
        }

        final errorCode = threeDSResult["errorcode"];
        final isSuccess = errorCode == "00";

        setState(() {
          _paymentState = isSuccess
              ? PaymentUIState.success
              : PaymentUIState.failure;
          _paymentMessage = isSuccess
              ? "Payment successful"
              : threeDSResult["errordesc"];
        });

        await Future.delayed(const Duration(seconds: 1));

        LatpayPaymentCallback.onPaymentCompleted?.call(threeDSResult);

        Navigator.pop(context);
        return;
      }

      /// NON-3DS FLOW
      final capture = data["Capture"];
      final errorCode = capture?["status"]?["errorcode"] ?? "";
      final errorDesc = capture?["status"]?["errordesc"] ?? "Payment failed";

      final bool isSuccess = errorCode == "00";

      /// Update popup UI
      setState(() {
        _paymentState = isSuccess
            ? PaymentUIState.success
            : PaymentUIState.failure;
        _paymentMessage = isSuccess ? "Payment successful" : errorDesc;
      });

      /// Prepare final response for merchant
      final result = isSuccess
          ? {
              "responsekey": capture["responsekey"],
              "amount": capture["amount"],
              "reference": capture["reference"],
              "description": capture["description"],
              "currency": capture["currency"],
              "errorcode": errorCode,
              "errordesc": errorDesc,
            }
          : {
              "responsekey": "",
              "amount": widget.amount.toStringAsFixed(2),
              "reference": "lpstest123",
              "description": "lpstest123",
              "currency": widget.currency,
              "errorcode": errorCode,
              "errordesc": errorDesc,
            };

      /// Show result for 1 second
      await Future.delayed(const Duration(seconds: 1));

      /// Final callback to merchant
      LatpayPaymentCallback.onPaymentCompleted?.call(result);

      Navigator.pop(context);
    } catch (e) {
      /// Unexpected failure
      setState(() {
        _paymentState = PaymentUIState.failure;
        _paymentMessage = "Payment failed. Please try again.";
      });

      await Future.delayed(const Duration(seconds: 1));

      LatpayPaymentCallback.onPaymentCompleted?.call({
        "responsekey": "",
        "amount": widget.amount.toStringAsFixed(2),
        "reference": "lpstest123",
        "description": "lpstest123",
        "currency": widget.currency,
        "errorcode": "90",
        "errordesc": e.toString(),
      });

      Navigator.pop(context);
    }
  }

  Future<void> _confirmCancelPayment() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Cancel Payment?"),
          ],
        ),
        content: const Text(
          "Your payment has not been completed yet. "
          "If you leave now, you will need to restart the payment process.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Continue Payment",
              style: TextStyle(color: Color.fromRGBO(37, 51, 113, 1)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(250, 73, 79, 1),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildKeyboardDoneBar(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (!keyboardVisible || _hideKeyboardBarManually) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _hideKeyboardBarManually = true;
                });

                FocusManager.instance.primaryFocus?.unfocus();

                // Reset after keyboard fully closes
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _hideKeyboardBarManually = false;
                    });
                  }
                });
              },
              child: const Text(
                "Done",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PaymentUIState { idle, processing, success, failure }
