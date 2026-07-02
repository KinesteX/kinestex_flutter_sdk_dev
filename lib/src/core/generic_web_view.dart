import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final bool isDarkMode;

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
    this.isDarkMode = true,
  });

  @override
  State<GenericWebView> createState() => _GenericWebViewState();
}

class _GenericWebViewState extends State<GenericWebView> {
  final _logger = KinesteXLogger.instance;
  String? _lastUpdatedExercise;
  final ValueNotifier<bool> _showOverlay = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _showRetry = ValueNotifier<bool>(false);
  Timer? _launchTimer;
  bool _launched = false;
  String _retryMessage = '';
  InAppWebViewController? _innerController;

  String get _connectionMessage =>
      _connectionMessageFor(widget.data['language']);

  @override
  void initState() {
    super.initState();
    _showOverlay.value = true;
    _loadView();
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    if (_innerController != null) {
      GenericWebView.controller.onWebViewDisposed(_innerController!);
    }
    _showOverlay.dispose();
    _showRetry.dispose();
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
    _launched = false;
    _showRetry.value = false;
    _showOverlay.value = true;
    _startLaunchTimer();

    GenericWebView.controller
        .loadView(
      apiKey: widget.apiKey,
      companyName: widget.companyName,
      userId: widget.userId,
      url: widget.url,
      data: widget.data,
      onMessageReceived: (message) {
        if (message is KinestexLaunched) {
          _launched = true;
          _launchTimer?.cancel();
        }
        if (message is KinestexLoaded) {
          _launchTimer?.cancel();
          Future.delayed(
            const Duration(milliseconds: 200),
            () {
              _showOverlay.value = false;
            },
          );
        }
        if (message is ErrorOccurred && !_launched) {
          _showRetryScreen(_errorMessageFrom(message));
        }
        widget.onMessageReceived(message);
      },
      isLoading: widget.isLoading,
    )
        .catchError((e) {
      _logger.error('Failed to load view: $e');
      if (mounted) widget.isLoading.value = false;
    });
  }

  void _startLaunchTimer() {
    _launchTimer?.cancel();
    _launchTimer = Timer(const Duration(seconds: 7), () {
      _logger.error('KinesteX did not launch within 7s — showing retry');
      _showRetryScreen(_connectionMessage);
    });
  }

  void _showRetryScreen(String message) {
    if (!mounted) return;
    _launchTimer?.cancel();
    _retryMessage = message;
    _showRetry.value = true;
  }

  String _errorMessageFrom(ErrorOccurred message) {
    final data = message.data;
    final nested = data['data'];
    String? text;
    if (nested is String) {
      text = nested;
    } else if (nested is Map && nested['message'] is String) {
      text = nested['message'] as String;
    } else if (data['message'] is String) {
      text = data['message'] as String;
    }
    return (text != null && text.trim().isNotEmpty)
        ? text.trim()
        : _connectionMessage;
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
              ),
              onConsoleMessage: (controller, consoleMessage) {
                // Silently handle console messages
              },
              onReceivedError: (controller, request, error) {
                _logger.error('WebView error: ${error.description}');
              },
              onWebViewCreated: (controller) {
                _innerController = controller;
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      final exitData = {
                        'type': 'exit_kinestex',
                        'timestamp': DateTime.now().toIso8601String(),
                      };
                      widget.onMessageReceived(ExitKinestex(exitData));
                      widget.showKinesteX.value = false;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(26.0),
                      child: SvgPicture.asset(
                        'packages/kinestex_sdk_flutter/assets/icons/ic_arrow_left.svg',
                        colorFilter: ColorFilter.mode(
                          widget.isDarkMode ? Colors.white : Colors.black,
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showRetry,
            builder: (context, showRetry, child) {
              if (!showRetry) return const SizedBox.shrink();
              final foregroundColor =
                  widget.isDarkMode ? Colors.white : Colors.black;
              return Container(
                color: widget.overlayColor,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          final exitData = {
                            'type': 'exit_kinestex',
                            'timestamp': DateTime.now().toIso8601String(),
                          };
                          widget.onMessageReceived(ExitKinestex(exitData));
                          widget.showKinesteX.value = false;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(26.0),
                          child: SvgPicture.asset(
                            'packages/kinestex_sdk_flutter/assets/icons/ic_arrow_left.svg',
                            colorFilter: ColorFilter.mode(
                              foregroundColor,
                              BlendMode.srcIn,
                            ),
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: _loadView,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: foregroundColor,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _retryMessage.isNotEmpty
                                    ? _retryMessage
                                    : _connectionMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _connectionMessageFor(dynamic language) {
  var code = language is String ? language.toLowerCase().trim() : '';
  code = code.split(RegExp(r'[-_]')).first;
  code = const {'iw': 'he', 'in': 'id'}[code] ?? code;
  return _connectionMessages[code] ?? _connectionMessages['en']!;
}

const Map<String, String> _connectionMessages = {
  'en': 'Please connect to the internet and try again',
  'ar': 'يرجى الاتصال بالإنترنت والمحاولة مرة أخرى',
  'es': 'Conéctate a Internet e inténtalo de nuevo',
  'it': 'Connettiti a Internet e riprova',
  'he': 'אנא התחבר לאינטרנט ונסה שוב',
  'zh': '请连接到互联网后重试',
  'pt': 'Conecte-se à Internet e tente novamente',
  'uk': 'Підключіться до Інтернету та повторіть спробу',
  'bn': 'অনুগ্রহ করে ইন্টারনেটে সংযুক্ত হয়ে আবার চেষ্টা করুন',
  'ru': 'Пожалуйста, подключитесь к интернету и повторите попытку',
  'hi': 'कृपया इंटरनेट से कनेक्ट करें और पुनः प्रयास करें',
  'id': 'Silakan sambungkan ke internet dan coba lagi',
  'fr': 'Veuillez vous connecter à Internet et réessayer',
  'el': 'Συνδεθείτε στο διαδίκτυο και δοκιμάστε ξανά',
  'nl': 'Maak verbinding met internet en probeer het opnieuw',
  'de':
      'Bitte stellen Sie eine Internetverbindung her und versuchen Sie es erneut',
  'uz': 'Iltimos, internetga ulaning va qayta urinib ko‘ring',
  'kk': 'Интернетке қосылып, қайталап көріңіз',
  'ja': 'インターネットに接続して、もう一度お試しください',
  'tr': 'Lütfen internete bağlanın ve tekrar deneyin',
  'ko': '인터넷에 연결한 후 다시 시도해 주세요',
};
