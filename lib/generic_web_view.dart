import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'models/kinestex_view_state.dart';
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

  @override
  void initState() {

    super.initState();
  }

  @override
  void didUpdateWidget(covariant GenericWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

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
                initialSettings: InAppWebViewSettings(

                  javaScriptEnabled: true,
                  allowsAirPlayForMediaPlayback: true,
                  allowsInlineMediaPlayback: true,
                  allowsBackForwardNavigationGestures: true,
                  mediaPlaybackRequiresUserGesture: false,

                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,


                ),

                onWebViewCreated: (InAppWebViewController controller) {
                  _controller = controller;
                  webViewState.setWebViewController(controller);
                  controller.addJavaScriptHandler(
                    handlerName: 'messageHandler',
                    callback: (args) {
                      try {
                        if (args.isNotEmpty) {
                          final dynamic data = args[0];
                          if (data is String) {
                            print('Received data as String: $data');
                            final Map<String, dynamic> decodedData = jsonDecode(data);
                            final WebViewMessage webViewMessage = WebViewMessage.fromJson(decodedData);
                            widget.onMessageReceived(webViewMessage);
                          } else if (data is Map<String, dynamic>) {
                            print('Received data as Map<String, dynamic>: $data');
                            final WebViewMessage webViewMessage = WebViewMessage.fromJson(data);
                            widget.onMessageReceived(webViewMessage);
                          } else {
                            print('Received data in unexpected format: $data');
                          }
                        } else {
                          print('No data received in messageHandler');
                        }
                      } catch (e, stackTrace) {
                        print('Error in messageHandler: $e');
                        print('Stack trace: $stackTrace');
                      }
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

  function checkReadiness() {
    if (document.readyState === 'complete') {
      sendMessage();
    } else {
      document.addEventListener('DOMContentLoaded', sendMessage);
    }
    
  }
  
    setTimeout(checkReadiness, 100); 
    
  """;


    try {
      if (_controller != null) {
       // log('sending message: $script');
        print("Loading initial data");
        await _controller!.evaluateJavascript(source: script);
        print("Initial data evaluated");
      }
    } catch (e) {
      log('KinesteX SDK: Error sending message: $e');
    }



  }
  String _mapToJson(Map<String, dynamic> map) {
    return map.entries
        .where((e) => e.key != 'exercises' && e.key != 'currentExercise')
        .map((e) => "'${e.key}': '${e.value}'")
        .join(', ');
  }

  Future<void> updateCurrentExercise(String exercise) async {
    final String script = '''
      window.postMessage({
        'currentExercise': '$exercise' }, '${widget.url}');
    ''';
    log("KinesteX SDK: Updating script:  $script");
    if (_controller != null) {
      await _controller!.evaluateJavascript(source: script);
    }
  }
}
