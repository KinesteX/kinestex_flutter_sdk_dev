import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_web_controller.dart';
import '../models/web_view_message.dart';

class GenericWebView extends StatefulWidget {
  static final KinesteXWebViewController controller =
      KinesteXWebViewController();

  static Future<void> warmup() async {
    return controller.warmup();
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

  @override
  void initState() {
    super.initState();
    _loadView();
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
      onMessageReceived: widget.onMessageReceived,
      isLoading: widget.isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use controller's current URL if available (warmup URL on first load)
    // Otherwise use widget's URL
    final initialUrl = GenericWebView.controller.currentUrl ?? widget.url;
    final headlessWebview = GenericWebView.controller.headlessWebView;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        final shouldPop = await GenericWebView.controller.onBackPressed();
        if (!shouldPop) {
          return; // WebView handled the back press
        }
        widget.showKinesteX.value = false;
      },
      child: Stack(
        children: [
          // Wrap WebView with Opacity - invisible during warmup, visible after
          Opacity(
            opacity: !GenericWebView.controller.isInitialized ? 0.0 : 1.0,
            child: InAppWebView(
              headlessWebView: headlessWebview,
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
              },
              onPermissionRequest: (controller, request) async {
                return GenericWebView.controller
                    .onPermissionRequest(controller, request);
              },
            ),
          ),
        ],
      ),
    );
  }
}
