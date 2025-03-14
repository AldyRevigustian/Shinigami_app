import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'web_view_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setSystemUIOverlay();
  
  // Mengoptimalkan mode UI sistem
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  // Gunakan callback yang lebih efisien
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PullToRefreshController pullToRefreshController;
  // Konstanta untuk URL dan warna background
  static const String initialUrl = "https://app.shinigami.asia/";
  static const Color backgroundColor = Color.fromRGBO(24, 24, 27, 1);

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
  }

  // Ekstrak metode untuk meningkatkan keterbacaan dan memudahkan pemeliharaan
  Future<void> _handleRefresh() async {
    final controller = WebViewHandler.webViewController;
    if (controller != null) {
      await controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Gunakan builder untuk mengoptimalkan performa MaterialApp
      builder: (context, child) => child!,
      home: WillPopScope(
        onWillPop: WebViewHandler.handleBackButton,
        child: Scaffold(
          backgroundColor: backgroundColor,
          // Gunakan const untuk widget yang tidak berubah
          body: _buildWebView(),
        ),
      ),
    );
  }

  // Ekstrak widget WebView ke metode terpisah
  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(initialUrl),
      ),
      onWebViewCreated: WebViewHandler.setWebViewController,
      initialOptions: _getWebViewOptions(),
      pullToRefreshController: pullToRefreshController,
      onLoadStop: (controller, url) {
        pullToRefreshController.endRefreshing();
        WebViewHandler.loadAndInjectJavaScript();
      },
    );
  }

  // Ekstrak opsi WebView ke metode terpisah
  InAppWebViewGroupOptions _getWebViewOptions() {
    return InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        cacheEnabled: true,
        clearCache: false,
        javaScriptEnabled: true,
        useOnDownloadStart: true,
        userAgent: "random",
        transparentBackground: true,
        // Tambahkan opsi untuk mempercepat loading
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        // Aktifkan opsi berikut untuk performa lebih baik
        preferredContentMode: UserPreferredContentMode.RECOMMENDED,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheMode: AndroidCacheMode.LOAD_DEFAULT,
        forceDark: AndroidForceDark.FORCE_DARK_ON,
        // Aktifkan opsi berikut untuk mempercepat rendering
        builtInZoomControls: false,
        displayZoomControls: false,
        // Gunakan Hardware Acceleration
        hardwareAcceleration: true,
      ),
      ios: IOSInAppWebViewOptions(
        // Opsi khusus iOS untuk performa lebih baik
        allowsAirPlayForMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        allowsLinkPreview: false,
        ignoresViewportScaleLimits: false,
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan resource saat widget dihapus
    pullToRefreshController.dispose();
    super.dispose();
  }
}