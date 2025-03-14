import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewHandler {
  static InAppWebViewController? webViewController;

  static void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  static Future<void> loadAndInjectJavaScript() async {
    if (webViewController == null) return;
    
    try {
      String jsContent = await rootBundle.loadString('assets/js/script.js');
      await webViewController!.evaluateJavascript(source: jsContent);
    } catch (e) {
      print('Error injecting JavaScript: $e');
    }
  }

  static Future<bool> handleBackButton() async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();
      if (canGoBack) {
        webViewController!.goBack();
        return false;
      }
    }
    return true;
  }
}