import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewHandler {
  static InAppWebViewController? webViewController;
  // Cache untuk script JS
  static String? _cachedJsContent;

  static void setWebViewController(InAppWebViewController controller) {
    webViewController = controller;
  }

  static Future<void> loadAndInjectJavaScript() async {
    if (webViewController == null) return;
    
    try {
      _cachedJsContent ??= await rootBundle.loadString('assets/js/script.js');
      await webViewController!.evaluateJavascript(source: _cachedJsContent!);
    } catch (e) {
      print('Error injecting JavaScript: $e');
    }
  }

  static Future<bool> handleBackButton() async {
    final controller = webViewController;
    if (controller != null) {
      final canGoBack = await controller.canGoBack();
      if (canGoBack) {
        controller.goBack();
        return false; // Cegah aplikasi keluar
      }
    }
    return true; // Jika tidak bisa back, keluar dari aplikasi
  }

  static void clearResources() {
    _cachedJsContent = null;
    webViewController = null;
  }

  static Future<void> preloadJavaScript() async {
    if (_cachedJsContent == null) {
      try {
        _cachedJsContent = await rootBundle.loadString('assets/js/script.js');
      } catch (e) {
        print('Error preloading JavaScript: $e');
      }
    }
  }
}