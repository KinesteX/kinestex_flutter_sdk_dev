import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';
import '../models/index.dart';

/// Singleton controller managing WebView lifecycle for optimal performance
///
/// Uses a headless WebView for warmup (engine initialization and resource caching),
/// then creates fresh InAppWebView instances with NO navigation history.
/// This prevents the iOS swipe-back issue while maintaining warmup benefits.
class KinesteXWebViewController {
  static final KinesteXWebViewController _instance =
      KinesteXWebViewController._internal();
  factory KinesteXWebViewController() => _instance;
  KinesteXWebViewController._internal();

  final _logger = KinesteXLogger.instance;

  // Defining our headlessWebView for initialization
  HeadlessInAppWebView? _headlessWebView;

  // WebView state
  InAppWebViewController? _webViewController;
  bool _isInitialized = false;
  static const String _warmupUrl = 'https://ai.kinestex.com/warmup';

  // Navigation state
  String? _currentUrl;
  String? _currentApiKey;
  String? _currentCompanyName;
  String? _currentUserId;
  Map<String, dynamic>? _currentData;

  // Callbacks
  Function(WebViewMessage)? _onMessageReceived;
  ValueNotifier<bool>? _isLoading;

  // Retry mechanism
  Timer? _launchTimer;
  int _retryCount = 0;
  final int _maxRetries = 3;

  bool _kinestexLoadedHandled = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentUrl => _currentUrl;
  HeadlessInAppWebView? get headlessWebView => _headlessWebView;

  Future<void> warmup({
    String? apiKey,
    String? companyName,
    String? userId,
  }) async {
    if (_isInitialized) {
      _logger.info('WebView already warmed up');
      return;
    }

    // Store credentials if provided during initialization
    if (apiKey != null && companyName != null && userId != null) {
      _currentApiKey = apiKey;
      _currentCompanyName = companyName;
      _currentUserId = userId;
      _currentUrl = _warmupUrl;
      _logger.info('Credentials stored during warmup');
    }

    _isInitialized = true;
    _logger.info('Starting headless WebView warmup...');

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_warmupUrl)),
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
      onWebViewCreated: (controller) {
        _logger.info('Headless WebView created');
      },
      onLoadStop: (controller, url) async {
        _logger.success('Warmup page fully loaded: $url');
        _launchTimer?.cancel();
        _retryCount = 0;
      },
      onReceivedError: (controller, request, error) {
        _logger.error('Warmup error: ${error.description}');
      },
    );

    await _headlessWebView?.run();
    _logger.success('Headless WebView warmup running');
  }

  Future<void> loadView({
    String? apiKey,
    String? companyName,
    String? userId,
    String? url,
    Map<String, dynamic>? data,
    Function(WebViewMessage)? onMessageReceived,
    required ValueNotifier<bool> isLoading,
  }) async {
    if (!_isInitialized) {
      _logger.error("WebView is not warmed up yet!");
      throw Exception("WebView is not warmed up before usage!");
    }

    _logger.info('Loading view: $url');
    _webViewController = null;

    // Store current state
    _currentUrl = url;
    _currentApiKey = apiKey;
    _currentCompanyName = companyName;
    _currentUserId = userId;
    _currentData = data;
    _onMessageReceived = onMessageReceived;
    _isLoading = isLoading;
    _kinestexLoadedHandled = false;

    // Set loading state
    isLoading.value = true;
  }

  /// Called when InAppWebView is created in the widget tree
  void onWebViewCreated(InAppWebViewController controller) {
    if (_headlessWebView != null) {
      _headlessWebView!.dispose();
      _headlessWebView = null;
    }
    if (_webViewController != null) {
      _logger.info(
          'Secondary WebView detected (popup) — not registering as primary');
      return;
    }
    _webViewController = controller;
    _logger.info('InAppWebView created and attached to controller');

    controller.addJavaScriptHandler(
      handlerName: 'messageHandler',
      callback: (args) => _handleMessage(args, controller),
    );
  }

  void _handleMessage(
      List<dynamic> args, InAppWebViewController senderController) {
    try {
      if (args.isEmpty) return;

      final dynamic data = args[0];
      Map<String, dynamic> decodedData;

      if (data is String) {
        _logger.info('Received data (String): $data');
        decodedData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        _logger.info('Received data (Map): $data');
        decodedData = data;
      } else {
        _logger.error('Received data in unexpected format: $data');
        return;
      }

      final WebViewMessage webViewMessage =
          WebViewMessage.fromJson(decodedData);

      // Handle special message types
      if (webViewMessage is KinestexLaunched) {
        _logger.info('KinesteX launched - canceling retry timer');
        _launchTimer?.cancel();
        _retryCount = 0;
      }

      if (decodedData['type'] == 'kinestex_loaded') {
        if (_kinestexLoadedHandled) {
          _logger.info('Duplicate kinestex_loaded ignored');
          return;
        }
        _kinestexLoadedHandled = true;
        _webViewController = senderController;
        Future.delayed(const Duration(milliseconds: 200), () {
          _isLoading?.value = false;
        });
        _loadInitialData();
      }

      if (_onMessageReceived != null) {
        _onMessageReceived!(webViewMessage);
      } else {
        _logger.info(
            'Message received but callback not set: ${decodedData['type']}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error in messageHandler: $e');
      _logger.error('Stack trace: $stackTrace');
    }
  }

  /// Load initial data into the WebView
  void _loadInitialData() async {
    if (_webViewController == null ||
        _currentApiKey == null ||
        _currentCompanyName == null ||
        _currentUserId == null ||
        _currentUrl == null) {
      _logger.error('Cannot load initial data - missing required state:\n'
          'controller: ${_webViewController != null}, '
          'apiKey: ${_currentApiKey != null}, '
          'company: ${_currentCompanyName != null}, '
          'userId: ${_currentUserId != null}, '
          'url: ${_currentUrl != null}');
      return;
    }

    _logger.info('Loading initial data');

    String script = """
    function sendMessage() {
      const message = {
        'key': '$_currentApiKey',
        'company': '$_currentCompanyName',
        'userId': '$_currentUserId',
        'exercises': ${jsonEncode(_currentData?['exercises'] ?? [])},
        'currentExercise': '${_currentData?['currentExercise'] ?? ''}',
        'customWorkoutExercises': ${jsonEncode(_currentData?['customWorkoutExercises'] ?? [])},
        ${_mapToJson(_currentData ?? {})}
      };
      window.postMessage(message, '$_currentUrl');
    }
    setTimeout(sendMessage, 100);
  """;

    _logger.info("Script: $script");

    try {
      await _webViewController!.evaluateJavascript(source: script);
      _logger.info('Initial data evaluated');

      // Set up retry mechanism
      _launchTimer?.cancel();
      _launchTimer = Timer(const Duration(seconds: 1), () {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _logger.error(
              'Initial data not received within 1 second. Resending. Attempt $_retryCount.');
          _loadInitialData();
        }
      });
    } catch (e) {
      _logger.error('Error sending message: $e');
    }
  }

  /// Update current exercise dynamically
  Future<void> updateCurrentExercise(String exercise) async {
    if (_webViewController == null || _currentUrl == null) {
      _logger.error('Cannot update exercise - WebView not ready');
      return;
    }

    final String script = '''
      window.postMessage({
        'currentExercise': '$exercise' }, '$_currentUrl');
    ''';

    _logger.info('Updating currentExercise: $exercise');
    try {
      await _webViewController!.evaluateJavascript(source: script);
    } catch (e) {
      _logger.error('Failed to update exercise', e);
    }
  }

  /// Send a custom action message to the WebView
  ///
  /// Used for triggering specific actions like starting workouts,
  /// pausing, resuming, etc.
  ///
  /// Example: sendAction("workout_activity_action", "start")
  Future<void> sendAction(String action, String value) async {
    if (_webViewController == null || _currentUrl == null) {
      _logger.error('Cannot send action - WebView not ready');
      return;
    }

    // Validate action
    if (action.isEmpty) {
      _logger.error('KinesteX SDK: Action type is required');
      return;
    }

    // Validate value
    if (value.isEmpty) {
      _logger.error('KinesteX SDK: Action value is required');
      return;
    }

    // Create message payload
    final messagePayload = {
      action: value,
    };

    final String script = '''
      (function() {
        const message = ${jsonEncode(messagePayload)};
        window.postMessage(message, '$_currentUrl');
      })();
    ''';

    _logger.info('Sending action: $action = $value');

    try {
      await _webViewController!.evaluateJavascript(source: script);
      _logger.info('Action sent successfully');
    } catch (e) {
      _logger.error('Failed to send action', e);
    }
  }

  void onWebViewDisposed(InAppWebViewController controller) {
    if (_webViewController == controller) {
      _webViewController = null;
      _logger.info('WebView controller cleared after widget dispose');
    }
  }

  /// Handle navigation (back button, etc.)
  Future<bool> onBackPressed() async {
    if (_webViewController == null) return true;

    if (await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      return false; // Don't pop the route
    }

    return true; // Allow pop
  }

  /// Handle load start
  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    _isLoading?.value = true;
  }

  /// Handle load stop (page finished loading)
  void onLoadStop(InAppWebViewController controller, WebUri? url) async {
    final loadedUrl = url?.toString();
    _logger.info('Page loaded: $loadedUrl');
  }

  /// Handle permission requests
  Future<PermissionResponse> onPermissionRequest(
      InAppWebViewController controller, PermissionRequest request) async {
    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  /// Dispose the controller and clean up resources
  Future<void> dispose() async {
    _logger.info('Disposing WebView controller...');

    _launchTimer?.cancel();
    _launchTimer = null;

    // Clear state
    _webViewController = null;
    _isInitialized = false;
    _currentUrl = null;
    _currentApiKey = null;
    _currentCompanyName = null;
    _currentUserId = null;
    _currentData = null;
    _onMessageReceived = null;
    _isLoading = null;
    _kinestexLoadedHandled = false;

    // Clear headlessWebView
    await _headlessWebView?.dispose();
    _headlessWebView = null;

    _logger.success('WebView controller disposed');
  }

  /// Convert map to JSON string for JavaScript
  String _mapToJson(Map<String, dynamic> map) {
    return map.entries
        .where((e) =>
            e.key != 'exercises' &&
            e.key != 'currentExercise' &&
            e.key != 'customWorkoutExercises')
        .map((e) => "'${e.key}': ${jsonEncode(e.value)}")
        .join(', ');
  }
}
