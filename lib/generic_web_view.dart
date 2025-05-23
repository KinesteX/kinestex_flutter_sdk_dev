import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'models/web_view_message.dart';

class GenericWebView extends StatefulWidget {
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
  _GenericWebViewState createState() => _GenericWebViewState();
}

class _GenericWebViewState extends State<GenericWebView> {
  InAppWebViewController? _controller;
  Timer? _launchTimer; // Add this
  int _retryCount = 0; // Add this
  final int _maxRetries = 3; // Add this

  @override
  void initState() {
    // PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    super.initState();
  }

  @override
  void dispose() {
    _launchTimer?.cancel(); // Add this
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GenericWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.updatedExercise != widget.updatedExercise &&
        widget.updatedExercise != null) {
      updateCurrentExercise(widget.updatedExercise!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        if (await _controller?.canGoBack() ?? false) {
          await _controller?.goBack();
          return;
        }
        widget.showKinesteX.value = false;
        return;
      },
      child: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowsAirPlayForMediaPlayback: true,
              allowsInlineMediaPlayback: true,
              allowsBackForwardNavigationGestures: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: true,
              // Add this
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
            ),
            onConsoleMessage: (controller, consoleMessage) {},
            onReceivedError: (controller, request, error) {},
            onWebViewCreated: (InAppWebViewController controller) {
              _controller = controller;
              controller.addJavaScriptHandler(
                handlerName: 'messageHandler',
                callback: (args) {
                  try {
                    if (args.isNotEmpty) {
                      final dynamic data = args[0];
                      if (data is String) {
                        log('Received data (S): $data');
                        final Map<String, dynamic> decodedData =
                            jsonDecode(data);
                        final WebViewMessage webViewMessage =
                            WebViewMessage.fromJson(decodedData);
                        // Cancel the retry timer
                        if (webViewMessage is KinestexLaunched) {
                          log("Dismissing timer");
                          _launchTimer?.cancel(); // Cancel the timer
                          _retryCount = 0; // Reset retry count
                        }
                        if (webViewMessage.data["type"] == "kinestex_loaded") {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            widget.isLoading.value = false;
                          });
                          _loadInitialData();
                        }
                        widget.onMessageReceived(webViewMessage);
                      } else if (data is Map<String, dynamic>) {
                        log('Received data (M): $data');
                        final WebViewMessage webViewMessage =
                            WebViewMessage.fromJson(data);
                        // Cancel the retry timer
                        if (webViewMessage is KinestexLaunched) {
                          log("Dismissing timer");
                          _launchTimer?.cancel(); // Cancel the timer
                          _retryCount = 0; // Reset retry count
                        }
                        if (webViewMessage.data["type"] == "kinestex_loaded") {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            widget.isLoading.value = false;
                          });
                          _loadInitialData();
                        }
                        widget.onMessageReceived(webViewMessage);
                      } else {
                        log('Received data in unexpected format: $data');
                      }
                    }
                  } catch (e, stackTrace) {
                    log('Error in messageHandler: $e');
                    log('Stack trace: $stackTrace');
                  }
                },
              );
            },
            onLoadStart: (controller, url) {
              widget.isLoading.value = true;
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.isLoading,
            builder: (context, isLoading, child) {
              return isLoading
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF000000),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _loadInitialData() async {
    String script = """
    function sendMessage() {
      const message = {
        'key': '${widget.apiKey}',
        'company': '${widget.companyName}',
        'userId': '${widget.userId}',
        'exercises': ${jsonEncode(widget.data['exercises'] ?? [])},
        'currentExercise': '${widget.data['currentExercise'] ?? ''}',
        ${_mapToJson(widget.data)}
      };
      window.postMessage(message, '${widget.url}');
    }
    setTimeout(sendMessage, 100); 
  """;

    try {
      if (_controller != null) {
        // log('sending message: $script');
        log("Loading initial data");
        await _controller!.evaluateJavascript(source: script);
        log("Initial data evaluated");
      }
    } catch (e) {
      log('KinesteX SDK: Error sending message: $e');
    }

    // Retry mechanism
    _launchTimer?.cancel();
    _launchTimer = Timer(const Duration(seconds: 1), () {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        log("Initial data not received within 1 seconds. Resending. Attempt $_retryCount.");
        _loadInitialData();
      }
    });
  }

  String _mapToJson(Map<String, dynamic> map) {
    // Use jsonEncode on the value to preserve its type in the JS object
    return map.entries
        .where((e) => e.key != 'exercises' && e.key != 'currentExercise')
        .map((e) => "'${e.key}': ${jsonEncode(e.value)}") // Use jsonEncode here
        .join(', ');
  }

  Future<void> updateCurrentExercise(String exercise) async {
    final String script = '''
      window.postMessage({
        'currentExercise': '$exercise' }, '${widget.url}');
    ''';
    log("KinesteX SDK: Updating currentExercise: $exercise");
    if (_controller != null) {
      await _controller!.evaluateJavascript(source: script);
    }
  }
}
