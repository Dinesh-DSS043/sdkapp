import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Latpay3DSecureScreen extends StatefulWidget {
  final Map<String, dynamic> threeDSData;

  const Latpay3DSecureScreen({super.key, required this.threeDSData});

  @override
  State<Latpay3DSecureScreen> createState() => _Latpay3DSecureScreenState();
}

class _Latpay3DSecureScreenState extends State<Latpay3DSecureScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handled = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            debugPrint("3DS onPageStarted: $url");
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            debugPrint("3DS onPageFinished: $url");

            _checkForFinalResult(url);
          },
        ),
      )
      ..loadHtmlString(_buildAutoPostHtml());
  }

  /// Auto-submit form to ACS (VBVURL)
  String _buildAutoPostHtml() {
    return '''
<!DOCTYPE html>
<html>
  <body onload="document.forms[0].submit()">
    <form method="POST" action="${widget.threeDSData["VBVURL"]}">
      <input type="hidden" name="PaReq" value="${widget.threeDSData["PAReq"]}" />
      <input type="hidden" name="MD" value="${widget.threeDSData["MD"]}" />
      <input type="hidden" name="TermUrl" value="${widget.threeDSData["TermURL"]}" />
    </form>
  </body>
</html>
''';
  }

  /// Detecting final redirect and extract Base64 JSON
  void _checkForFinalResult(String url) {
    if (_handled) return;

    // Works for both staging and live
    if (url.contains('/SecurementResult')) {
      _handled = true;
      _handleFinalRedirect(url);
    }
  }

  /// Decoding Base64 JSON and notify merchant
  void _handleFinalRedirect(String url) {
    Map<String, dynamic> result;

    try {
      final uri = Uri.parse(url);
      final encodedJson = uri.queryParameters['json'];

      if (encodedJson == null || encodedJson.isEmpty) {
        throw Exception("Missing json parameter");
      }

      final decodedString = utf8.decode(base64.decode(encodedJson));

      debugPrint("3DS FINAL BASE64 JSON => $decodedString");

      final Map<String, dynamic> decoded = jsonDecode(decodedString);

      final capture = decoded["Capture"];
      if (capture == null) {
        throw Exception("Capture missing in response");
      }

      result = {
        "responsekey": capture["responsekey"],
        "amount": capture["amount"],
        "reference": capture["reference"],
        "description": capture["description"],
        "currency": capture["currency"],
        "errorcode": capture["status"]["errorcode"],
        "errordesc": capture["status"]["errordesc"],
      };

      // LatpayCheckout.OnPaymentCompleted
      // LatpayPaymentCallback.onPaymentCompleted?.call(re);
    } catch (e) {
      debugPrint("3DS final decode failed: $e");

      // LatpayPaymentCallback.onPaymentCompleted?.call({
      //   "responsekey": "",
      //   "amount": "",
      //   "reference": "",
      //   "description": "",
      //   "currency": "",
      //   "errorcode": "9090",
      //   "errordesc": "3DS finalization failed",
      // });
      result = {
        "responsekey": "",
        "amount": "",
        "reference": "",
        "description": "",
        "currency": "",
        "errorcode": "9090",
        "errordesc": "3DS finalization failed",
      };
    }

    // Closing WebView
    if (mounted) {
      // Navigator.pop(context);
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Secure 3D Payment"),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}