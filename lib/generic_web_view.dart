import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'kinestex_sdk.dart';

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
  final bool isHideHeaderMain; // Add the new parameter

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
    this.isHideHeaderMain = false, // Set the default value to false
  });

  @override
  _GenericWebViewState createState() => _GenericWebViewState();
}

class _GenericWebViewState extends State<GenericWebView> {
  InAppWebViewController? _controller;

  @override
  void initState() {
    log("Initialized - -------------  >  ${widget.updatedExercise}");
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GenericWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    log("Updated - -------------  >  ${widget.updatedExercise}");

    if (oldWidget.updatedExercise != widget.updatedExercise && widget.updatedExercise != null) {
      updateCurrentExercise(widget.updatedExercise!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KinesteXViewState>(
      builder: (context, webViewState, child) {
        return WillPopScope(
          onWillPop: () async {
            final webViewController = webViewState.webViewController;
            if (await webViewController?.canGoBack() ?? false) {
              webViewController?.goBack();
              return false;
            }
            widget.showKinesteX.value = false;
            return false;
          },
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false, // Disable autoplay

                  ),

                  ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true, // Allow inline media playback
                    allowsAirPlayForMediaPlayback: true
                  ),
                ),
                onWebViewCreated: (InAppWebViewController controller) {
                  _controller = controller;
                  webViewState.setWebViewController(controller);

                  controller.addJavaScriptHandler(
                    handlerName: 'messageHandler',
                    callback: (args) {
                      log('- - - - - Received - - - -  >>>>   ${args} ');
                      final Map<String, dynamic> data = jsonDecode(args[0]);
                      final WebViewMessage webViewMessage =
                      WebViewMessage.fromJson(data);
                      widget.onMessageReceived(webViewMessage);
                    },
                  );
                },
                onLoadStop: (controller, url) async {
                  widget.isLoading.value = false;
                  _loadInitialData();
                },
                onLoadStart: (controller, url) {
                  widget.isLoading.value = true;
                },
                onConsoleMessage: (controller, consoleMessage) {
                  print("WebViewMessage console:  " + consoleMessage.message);
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
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadInitialData() async {
    final String script = '''
    window.postMessage({
      'key': '${widget.apiKey}',
      'company': '${widget.companyName}',
      'userId': '${widget.userId}',
      'exercises': ${jsonEncode(widget.data['exercises'] ?? [])},
      'currentExercise': '${widget.data['currentExercise'] ?? ''}',
      'isHideHeaderMain': ${widget.isHideHeaderMain},
      ${_mapToJson(widget.data)}
    }, '${widget.url}');
  ''';

    if (_controller != null) {
      await _controller!.evaluateJavascript(source: script);
      await _controller!.evaluateJavascript(source: """
                    window.addEventListener('message', (event) => {
                      if (event.data === 'exitApp') {
                        window.flutter_inappwebview.callHandler('exitApp');
                      } else {
                        window.flutter_inappwebview.callHandler('messageHandler', event.data);
                      }
                    });
                  """);
    }

    print("Script: $script");
  }

  String _mapToJson(Map<String, dynamic> map) {
    return map.entries
        .where((e) => e.key != 'exercises' && e.key != 'currentExercise' && e.key != 'isHideHeaderMain')
        .map((e) => "'${e.key}': '${e.value}'")
        .join(', ');
  }

  Future<void> updateCurrentExercise(String exercise) async {
    final String script = '''
      window.postMessage({
        'currentExercise': '$exercise' }, '*');
    ''';
    log("Update - ------------- script  >  $script");
    if (_controller != null) {
      await _controller!.evaluateJavascript(source: script);
    }
  }
}
