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
      options: PullToRefreshOptions(
        color: Colors.white,
        backgroundColor: backgroundColor,
      ),
      onRefresh: _handleRefresh,
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadSavedUrl();

    _showFabTemporarily();

    setState(() {
      isInitialized = true;
    });
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

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('webview_url');

    setState(() {
      currentUrl = savedUrl ?? defaultUrl;
    });
  }

  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webview_url', url);
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

    return WillPopScope(
      onWillPop: WebViewHandler.handleBackButton,
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
                    backgroundColor: Color.fromRGBO(39, 39, 42, 1),
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
      initialOptions: _getWebViewOptions(),
      pullToRefreshController: pullToRefreshController,
      onLoadStop: (controller, url) {
        pullToRefreshController.endRefreshing();
        WebViewHandler.loadAndInjectJavaScript();

        _showFabTemporarily();
      },
    );
  }

  InAppWebViewGroupOptions _getWebViewOptions() {
    return InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        cacheEnabled: true,
        clearCache: false,
        javaScriptEnabled: true,
        useOnDownloadStart: true,
        userAgent: "random",
        transparentBackground: true,

        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,

        preferredContentMode: UserPreferredContentMode.RECOMMENDED,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheMode: AndroidCacheMode.LOAD_DEFAULT,
        forceDark: AndroidForceDark.FORCE_DARK_ON,

        builtInZoomControls: false,
        displayZoomControls: false,

        hardwareAcceleration: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsAirPlayForMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        allowsLinkPreview: false,
        ignoresViewportScaleLimits: false,
      ),
    );
  }

  @override
  void dispose() {
    fabTimer?.cancel();
    pullToRefreshController.dispose();
    super.dispose();
  }
}
