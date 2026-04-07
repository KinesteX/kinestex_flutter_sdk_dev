import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_web_controller.dart';
import '../models/web_view_message.dart';

class GenericWebView extends StatefulWidget {
  static final KinesteXWebViewController controller =
      KinesteXWebViewController();

  static Future<void> warmup({
    String? apiKey,
    String? companyName,
    String? userId,
  }) async {
    return controller.warmup(
      apiKey: apiKey,
      companyName: companyName,
      userId: userId,
    );
  }

  /// Dispose the WebView controller
  ///
  /// Call this when you want to completely clean up the SDK,
  /// typically when your app is closing.
  static Future<void> disposeWarmup() async {
    return controller.dispose();
  }

  /// Check if WebView has been warmed up
  static bool get isWarmedUp => controller.isInitialized;
  final String apiKey;
  final String companyName;
  final String userId;
  final String url;
  final Map<String, dynamic> data;
  final Color overlayColor;
  final Function(WebViewMessage) onMessageReceived;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<bool> showKinesteX;
  final String? updatedExercise;

  const GenericWebView({
    super.key,
    required this.apiKey,
    required this.companyName,
    required this.userId,
    required this.url,
    required this.data,
    required this.overlayColor,
    required this.onMessageReceived,
    required this.isLoading,
    required this.showKinesteX,
    this.updatedExercise,
  });

  @override
  State<GenericWebView> createState() => _GenericWebViewState();
}

class _GenericWebViewState extends State<GenericWebView> {
  final _logger = KinesteXLogger.instance;
  String? _lastUpdatedExercise;
  final ValueNotifier<bool> _showOverlay = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _showOverlay.value = true;
    _loadView();
  }

  @override
  void dispose() {
    _showOverlay.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GenericWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if parameters changed
    final paramsChanged = oldWidget.url != widget.url ||
        oldWidget.apiKey != widget.apiKey ||
        oldWidget.companyName != widget.companyName ||
        oldWidget.userId != widget.userId ||
        oldWidget.data != widget.data;

    if (paramsChanged) {
      _logger.info('Parameters changed, reloading view');
      _showOverlay.value = true;
      _loadView();
    }

    // Handle exercise updates
    if (oldWidget.updatedExercise != widget.updatedExercise &&
        widget.updatedExercise != null &&
        widget.updatedExercise != _lastUpdatedExercise) {
      _lastUpdatedExercise = widget.updatedExercise;
      GenericWebView.controller.updateCurrentExercise(widget.updatedExercise!);
    }
  }

  /// Load the view using the singleton controller
  void _loadView() {
    GenericWebView.controller.loadView(
      apiKey: widget.apiKey,
      companyName: widget.companyName,
      userId: widget.userId,
      url: widget.url,
      data: widget.data,
      onMessageReceived: (message) {
        if (message is KinestexLoaded) {
          Future.delayed(
            const Duration(milliseconds: 200),
            () {
              _showOverlay.value = false;
            },
          );
        }
        widget.onMessageReceived(message);
      },
      isLoading: widget.isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialUrl = widget.url;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamicType) async {
        final shouldPop = await GenericWebView.controller.onBackPressed();
        if (!shouldPop) {
          return;
        }

        final Map<String, dynamic> exitKinestexData = {
          'type': 'exit_kinestex',
          'timestamp': DateTime.now().toIso8601String(),
        };
        final WebViewMessage exitKinestexMessage =
            ExitKinestex(exitKinestexData);
        widget.onMessageReceived(exitKinestexMessage);

        widget.showKinesteX.value = false;
      },
      child: Stack(
        children: [
          Opacity(
            opacity: !GenericWebView.controller.isInitialized ? 0.0 : 1.0,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowsAirPlayForMediaPlayback: true,
                allowsInlineMediaPlayback: true,
                allowsBackForwardNavigationGestures: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true,
                verticalScrollBarEnabled: false,
                horizontalScrollBarEnabled: false,
                upgradeKnownHostsToHTTPS: false,
              ),
              onConsoleMessage: (controller, consoleMessage) {
                // Silently handle console messages
              },
              onReceivedError: (controller, request, error) {
                _logger.error('WebView error: ${error.description}');
              },
              onWebViewCreated: (controller) {
                GenericWebView.controller.onWebViewCreated(controller);
              },
              onLoadStart: (controller, url) {
                GenericWebView.controller.onLoadStart(controller, url);
              },
              onLoadStop: (controller, url) {
                GenericWebView.controller.onLoadStop(controller, url);
                // Fix dvh viewport height issue by injecting correct dimensions
                final mediaQuery = MediaQuery.of(context);
                final height = mediaQuery.size.height -
                    mediaQuery.padding.top -
                    mediaQuery.padding.bottom;
                final width = mediaQuery.size.width;
                controller.evaluateJavascript(source: '''
                  (function() {
                    var h = ${height.toInt()};
                    var w = ${width.toInt()};
                    document.documentElement.style.setProperty('--viewport-height', h + 'px');
                    document.documentElement.style.setProperty('--vh', (h * 0.01) + 'px');
                    document.documentElement.style.height = h + 'px';
                    document.body.style.height = h + 'px';
                    window.dispatchEvent(new Event('resize'));
                  })();
                ''');
              },
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
              },
              onPermissionRequest: (controller, request) async {
                return GenericWebView.controller
                    .onPermissionRequest(controller, request);
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showOverlay,
            builder: (context, showOverlay, child) {
              if (!showOverlay) return const SizedBox.shrink();
              return Container(
                color: widget.overlayColor,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
        ],
      ),
    );
  }
}
