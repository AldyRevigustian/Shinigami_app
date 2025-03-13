import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setSystemUIOverlay(); // Panggil di sini
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    await Future.delayed(Duration(seconds: 0), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
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
  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.white, // Warna progress indicator
        backgroundColor: Color.fromRGBO(24, 24, 27, 1),
      ),
      onRefresh: () async {
        if (webViewController != null) {
          await webViewController!.reload();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: () async {
          if (webViewController != null) {
            bool canGoBack = await webViewController!.canGoBack();
            if (canGoBack) {
              webViewController!.goBack();
              return false; // Cegah aplikasi keluar
            }
          }
          return true; // Jika tidak bisa back, keluar dari aplikasi
        },
        child: Scaffold(
          backgroundColor: Color.fromRGBO(24, 24, 27, 1),
          body: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("https://app.shinigami.asia/"),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                useOnDownloadStart: true,
                userAgent: "random",
                transparentBackground: true,
              ),
              android: AndroidInAppWebViewOptions(useHybridComposition: true),
            ),
            pullToRefreshController: pullToRefreshController, // Tambahkan ini
            onLoadStop: (controller, url) {
              pullToRefreshController
                  .endRefreshing(); // Hentikan animasi pull-to-refresh

              controller.evaluateJavascript(
                source: """
                function removeAds() {
                  document.querySelectorAll('.grid.grid-cols-1.md\\\\:grid-cols-2.md\\\\:gap-4.gap-4').forEach(el => el.remove());

                  if (window.location.pathname.startsWith('/chapter/')) {
                    document.querySelectorAll('.fixed.bottom-0.left-0.w-screen.h-\\\\[calc\\\\(100dvh\\\\)\\\\].md\\\\:h-screen.bg-base-bg\\\\/40.z-\\\\[208\\\\].flex.flex-col.justify-end.items-start').forEach(el => el.remove());

                    document.querySelectorAll('.max-w-800.mx-auto.w-full.pb-12.lg\\\\:pb-12.relative.z-\\\\[207\\\\]').forEach(el => el.remove());
                  }
                }

                function modifyNavbar() {
                  if (window.location.pathname.startsWith('/chapter/')) {
                    return; // Jangan modifikasi navbar jika di halaman /chapter/
                  }

                  const navbar = document.querySelector('.md\\\\:px-64.px-16.md\\\\:py-24.py-16.lg\\\\:h-100.transition-all.bg-base-bg.border-b.border-base-white\\\\/10.flex');
                  if (navbar) {
                    navbar.style.height = '95px';

                    const firstChild = navbar.querySelector(':first-child');
                    if (firstChild) {
                      firstChild.style.paddingTop = '25px';
                    }
                  }
                }

                // Jalankan fungsi awal
                removeAds();
                modifyNavbar();

                const observer = new MutationObserver(mutations => {
                  mutations.forEach(mutation => {
                    mutation.addedNodes.forEach(node => {
                      if (node.nodeType === 1) {
                        // Hapus iklan jika elemen baru sesuai dengan selektor
                        if (node.matches('.grid.grid-cols-1.md\\\\:grid-cols-2.md\\\\:gap-4.gap-4')) {
                          node.remove();
                        }

                        if (window.location.pathname.startsWith('/chapter/')) {
                          if (node.matches('.fixed.bottom-0.left-0.w-screen.h-\\\\[calc\\\\(100dvh\\\\)\\\\].md\\\\:h-screen.bg-base-bg\\\\/40.z-\\\\[208\\\\].flex.flex-col.justify-end.items-start')) {
                            node.remove();
                          }
                          if (node.matches('.max-w-800.mx-auto.w-full.pb-12.lg\\\\:pb-12.relative.z-\\\\[207\\\\]')) {
                            node.remove();
                          }
                        } else {
                          // Modifikasi navbar hanya jika bukan halaman /chapter/
                          if (node.matches('.md\\\\:px-64.px-16.md\\\\:py-24.py-16.lg\\\\:h-100.transition-all.bg-base-bg.border-b.border-base-white\\\\/10.flex')) {
                            node.style.height = '95px';

                            const firstChild = node.querySelector(':first-child');
                            if (firstChild) {
                              firstChild.style.paddingTop = '25px';
                            }
                          }
                        }
                      }
                    });
                  });
                });

                observer.observe(document.body, { childList: true, subtree: true });
              """,
              );
            },
          ),
        ),
      ),
    );
  }
}
