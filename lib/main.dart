import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'web_view_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setSystemUIOverlay();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    await Future.delayed(Duration(seconds: 0), () {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    });

    return Future.value();
  });

  runApp(MyApp());
}

void setSystemUIOverlay() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color.fromRGBO(24, 24, 27, 1),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PullToRefreshController pullToRefreshController;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.white,
        backgroundColor: Color.fromRGBO(24, 24, 27, 1),
      ),
      onRefresh: () async {
        if (WebViewHandler.webViewController != null) {
          await WebViewHandler.webViewController!.reload();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: WebViewHandler.handleBackButton,
        child: Scaffold(
          backgroundColor: Color.fromRGBO(24, 24, 27, 1),
          body: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("https://app.shinigami.asia/"),
            ),
            onWebViewCreated: (controller) {
              WebViewHandler.setWebViewController(controller);
            },
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                cacheEnabled: true,
                clearCache: false,
                javaScriptEnabled: true,
                useOnDownloadStart: true,
                userAgent: "random",
                transparentBackground: true,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheMode: AndroidCacheMode.LOAD_DEFAULT,
                forceDark: AndroidForceDark.FORCE_DARK_ON,
              ),
            ),
            pullToRefreshController: pullToRefreshController,
            onLoadStop: (controller, url) {
              pullToRefreshController.endRefreshing();
              WebViewHandler.loadAndInjectJavaScript();
            },
          ),
        ),
      ),
    );
  }
}