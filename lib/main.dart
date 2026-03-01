import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'web_view_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setSystemUIOverlay();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    return Future.value();
  });

  runApp(const MyApp());
}

void setSystemUIOverlay() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color.fromRGBO(24, 24, 27, 1),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final PullToRefreshController pullToRefreshController;
  late final InAppWebViewSettings _webViewSettings;
  SharedPreferences? _prefs;

  static const String defaultUrl = "https://app.shinigami.asia/";
  static const Color backgroundColor = Color.fromRGBO(24, 24, 27, 1);

  String? currentUrl;
  bool isFabVisible = false;
  Timer? fabTimer;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.white,
        backgroundColor: backgroundColor,
      ),
      onRefresh: _handleRefresh,
    );

    _webViewSettings = _buildWebViewSettings();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    final savedUrl = _prefs!.getString('webview_url') ?? defaultUrl;

    if (!mounted) return;
    setState(() {
      currentUrl = savedUrl;
      isInitialized = true;
    });

    _showFabTemporarily();
  }

  void _showFabTemporarily() {
    fabTimer?.cancel();

    setState(() {
      isFabVisible = true;
    });

    fabTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isFabVisible = false;
        });
      }
    });
  }

  Future<void> _saveUrl(String url) async {
    await _prefs!.setString('webview_url', url);
    setState(() {
      currentUrl = url;
    });
  }

  Future<void> _handleRefresh() async {
    final controller = WebViewHandler.webViewController;
    if (controller != null) {
      await controller.reload();
    }
  }

  void _showUrlEditDialog() {
    final TextEditingController urlController = TextEditingController(
      text: currentUrl,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit WebView URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newUrl = urlController.text.trim();
                if (newUrl.isNotEmpty) {
                  if (!newUrl.startsWith('http')) {
                    newUrl = 'https://$newUrl';
                  }

                  await _saveUrl(newUrl);

                  if (WebViewHandler.webViewController != null) {
                    await WebViewHandler.webViewController!.loadUrl(
                      urlRequest: URLRequest(url: WebUri(newUrl)),
                    );
                  }

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || currentUrl == null) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await WebViewHandler.handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: GestureDetector(
          onTap: _showFabTemporarily,
          child: _buildWebView(),
        ),
        floatingActionButton:
            isFabVisible
                ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 80),
                  child: FloatingActionButton(
                    elevation: 2,
                    onPressed: _showUrlEditDialog,
                    backgroundColor: const Color.fromRGBO(39, 39, 42, 1),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(currentUrl!)),
      onWebViewCreated: WebViewHandler.setWebViewController,
      initialSettings: _webViewSettings,
      pullToRefreshController: pullToRefreshController,
      shouldOverrideUrlLoading: (controller, action) async {
        return NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) {
        pullToRefreshController.endRefreshing();
        WebViewHandler.loadAndInjectJavaScript();
      },
      onLoadError: (controller, url, code, message) {
        pullToRefreshController.endRefreshing();
      },
    );
  }

  InAppWebViewSettings _buildWebViewSettings() {
    return InAppWebViewSettings(
      // Cross-platform settings
      cacheEnabled: true,
      clearCache: false,
      javaScriptEnabled: true,
      useOnDownloadStart: true,
      transparentBackground: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      preferredContentMode: UserPreferredContentMode.RECOMMENDED,

      // Android-specific settings
      useHybridComposition: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      forceDark: ForceDark.ON,
      builtInZoomControls: false,
      displayZoomControls: false,
      hardwareAcceleration: true,

      // iOS-specific settings
      allowsAirPlayForMediaPlayback: true,
      allowsBackForwardNavigationGestures: true,
      allowsLinkPreview: false,
      ignoresViewportScaleLimits: false,
    );
  }

  @override
  void dispose() {
    fabTimer?.cancel();
    pullToRefreshController.dispose();
    super.dispose();
  }
}
