import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'latpay_payment_callback.dart';

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

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'latpay_payment_callback.dart';

class Latpay3DSecureScreen extends StatefulWidget {
  final Map<String, dynamic> threeDSData;

  const Latpay3DSecureScreen({
    super.key,
    required this.threeDSData,
  });

  @override
  State<Latpay3DSecureScreen> createState() => _Latpay3DSecureScreenState();
}

class _Latpay3DSecureScreenState extends State<Latpay3DSecureScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handled = false;

  @override
  void initState() {
    print("dk init state");
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LatpayChannel',
        onMessageReceived: (message) {
          print("dk onMesageReceived state - ${message}");
          _handleConsoleMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) async {
            setState(() => _loading = false);
            print("dk onPageFinished state");
            // 🔐 Inject console hook once page loads
            await _injectConsoleHook();
          },
        ),
      )
      ..loadHtmlString(_buildAutoPostHtml());
  }

  /// 🔁 Auto-submit form
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

  /// 🧠 Inject console.log interceptor
  Future<void> _injectConsoleHook() async {
    print("dk injectedconsolehook state");
    const js = '''
      (function() {
        if (window.__latpayHooked) return;
        window.__latpayHooked = true;

        const originalLog = console.log;
        console.log = function(msg) {
          try {
            if (typeof msg === 'string' && msg.includes('"Capture"')) {
              LatpayChannel.postMessage(msg);
            }
          } catch (e) {}
          originalLog.apply(console, arguments);
        };
      })();
    ''';

    await _controller.runJavaScript(js);
  }

  /// 📩 Handle Valitor console output
  void _handleConsoleMessage(String message) {
    print("dk handleconsolemessage state - $message");
    if (_handled) return;
    _handled = true;

    try {
      debugPrint("3DS CONSOLE MESSAGE => $message");

      final Map<String, dynamic> decoded = jsonDecode(message);
      final capture = decoded["Capture"];

      final res = {
        "responsekey": capture["responsekey"],
        "amount": capture["amount"],
        "reference": capture["reference"],
        "description": capture["description"],
        "currency": capture["currency"],
        "errorcode": capture["status"]["errorcode"],
        "errordesc": capture["status"]["errordesc"],
      };

      LatpayPaymentCallback.onPaymentCompleted?.call(res);
    } catch (e) {
      LatpayPaymentCallback.onPaymentCompleted?.call({
        "responsekey": "",
        "amount": "",
        "reference": "",
        "description": "",
        "currency": "",
        "errorcode": "9090",
        "errordesc": "3DS parsing failed",
      });
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
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
*/
/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'latpay_payment_callback.dart';

class Latpay3DSecureScreen extends StatefulWidget {
  final Map<String, dynamic> threeDSData;

  const Latpay3DSecureScreen({
    super.key,
    required this.threeDSData,
  });

  @override
  State<Latpay3DSecureScreen> createState() => _Latpay3DSecureScreenState();
}

class _Latpay3DSecureScreenState extends State<Latpay3DSecureScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handled3DS = false;

  @override
  void initState() {
    print("dk init state");
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            print("dk onPageStarted state");
            setState(() => _loading = true);
          },
          onPageFinished: (url) async {
            print("dk onPageFinished state");
            setState(() => _loading = false);

            print("dk the threedsdata are: ${widget.threeDSData.toString()}");

            // 🔐 Detect TermURL completion
            if (!_handled3DS &&
                widget.threeDSData["TermURL"] != null &&
                url.startsWith(widget.threeDSData["TermURL"])) {
                  print("dk handle3ds state");
              _handled3DS = true;
              await _handle3DSCompletionFromPage();
            }
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadHtmlString(_buildAutoPostHtml());
  }

  /// 🔁 Auto-submit form to VBVURL
  String _buildAutoPostHtml() {
    print("dk autohtml state");
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

  /// 🧠 Parse JSON from TermURL page (Valitor/Rapyd style)
  Future<void> _handle3DSCompletionFromPage() async {
    print("dk 3dcompletionfrompage state");
    try {
      // Read page content
      final raw = await _controller.runJavaScriptReturningResult(
        'document.body.innerText',
      );

      final text = raw.toString().replaceAll('"', '');
      debugPrint("3DS PAGE CONTENT => $text");

      final Map<String, dynamic> decoded = jsonDecode(text);

      final capture = decoded["Capture"];
      if (capture == null) {
        throw Exception("Capture section missing");
      }

      final res = {
        "responsekey": capture["responsekey"],
        "amount": capture["amount"],
        "reference": capture["reference"],
        "description": capture["description"],
        "currency": capture["currency"],
        "errorcode": capture["status"]["errorcode"],
        "errordesc": capture["status"]["errordesc"],
      };

      // 🔔 Notify merchant
      LatpayPaymentCallback.onPaymentCompleted?.call(res);
    } catch (e) {
      debugPrint("❌ 3DS parse failed: $e");

      LatpayPaymentCallback.onPaymentCompleted?.call({
        "responsekey": "",
        "amount": "",
        "reference": "",
        "description": "",
        "currency": "",
        "errorcode": "9090",
        "errordesc": "3DS verification failed",
      });
    }

    // 🔚 Close 3DS screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 Disable back button
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
*/

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'latpay_payment_callback.dart';

class Latpay3DSecureScreen extends StatefulWidget {
  final Map<String, dynamic> threeDSData;

  const Latpay3DSecureScreen({
    super.key,
    required this.threeDSData,
  });

  @override
  State<Latpay3DSecureScreen> createState() => _Latpay3DSecureScreenState();
}

class _Latpay3DSecureScreenState extends State<Latpay3DSecureScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            print("The onPageStarted url: $url");
          },
          onPageFinished: (url) {
            setState(() => _loading = false);

            print("The onPageFinished url: $url");
            // print("The onPageFinished Response: ${widget.threeDSData}");

            /// Detecting TermURL (3DS completed)
            if (url.startsWith(widget.threeDSData["TermURL"])) {
              _handle3DSCompleted();
            }
          },
          onNavigationRequest: (request) {
            /// Block navigation away from trusted flow if needed
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildAutoPostHtml());
  }

  /// Auto-submitting HTML
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

  /// Called when bank redirects back to TermURL
  void _handle3DSCompleted() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
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
*/
