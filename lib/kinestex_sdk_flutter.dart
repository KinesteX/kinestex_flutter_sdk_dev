library kinestex_sdk_flutter;

import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';

import '../models/index.dart';

enum WebViewLaunchStatus { init, success, loading, error, exit }

class KinesteXWebView extends StatefulWidget {
  const KinesteXWebView({
    super.key,
    required this.apiKey,
    required this.onHandleMessage,
    required this.userId,
    required this.workOutCategory,
    required this.planCategory,
    required this.companyName,
    required this.onLoadStop,
  });

  final String apiKey;
  final String userId;
  final String companyName;
  final WorkOutCategory workOutCategory;
  final PlanCategory planCategory;
  final VoidCallback onLoadStop;
  final Function(Map<String, dynamic> message) onHandleMessage;

  @override
  State<KinesteXWebView> createState() => _KinesteXWebViewState();
}

class _KinesteXWebViewState extends State<KinesteXWebView> {
  InAppWebViewController? _controller;
  String url = "https://kinestex.vercel.app/";

  late Map<String, String> postData;

  final ValueNotifier<WebViewLaunchStatus> _webLaunchStatus =
  ValueNotifier<WebViewLaunchStatus>(WebViewLaunchStatus.init);

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      javaScriptEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _inits();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ValueListenableBuilder<WebViewLaunchStatus>(
        valueListenable: _webLaunchStatus,
        builder: (context, status, __) {
          if (status == WebViewLaunchStatus.loading) {
            return _buildLoadingIndicator();
          }
          if (status == WebViewLaunchStatus.error) {
            return _buildError(null);
          }
          return _buildWebView();
        },
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialOptions: options,
      initialUrlRequest: URLRequest(url: Uri.parse(url)),
      onWebViewCreated: (InAppWebViewController controller) {
        _controller = controller;
        print("WebView Created"); // Debugging print

        controller.addJavaScriptHandler(
          handlerName: 'messageHandler',
          callback: (args) {
            print("Received message: $args"); // Debugging print
            handleMessage(args[0]);
          },
        );
      },
      onLoadStop: (InAppWebViewController controller, url) async {
        widget.onLoadStop.call();
        _sendDataToWebView();
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("CONSOLEEEEE: $consoleMessage");
      },
      onProgressChanged: (InAppWebViewController controller, int progress) {
        print("WebView is loading (progress : $progress%)");
      },
      onLoadError: (InAppWebViewController controller, Uri? url, int code,
          String message) {
        print("Failed to load: $url with error $message (Code: $code)");
      },
      androidOnPermissionRequest: (InAppWebViewController controller,
          String origin, List<String> resources) async {
        return PermissionRequestResponse(
            resources: resources,
            action: PermissionRequestResponseAction.GRANT);
      },
    );
  }

  Widget _buildError(String? error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline,
          color: Colors.red,
        ),
        const SizedBox(
          height: 14,
        ),
        Text(
          error ?? 'Something went wrong with your credentials',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator.adaptive());
  }

  void _inits() {
    _webLaunchStatus.value = WebViewLaunchStatus.loading;

    final userId = widget.userId;
    final companyName = widget.companyName;
    final apiKey = widget.apiKey;

    final isValidCred = isValidCredentials(
      userId: userId,
      companyName: companyName,
      apiKey: apiKey,
    );

    final planC = _getPlanCategory(widget.planCategory);
    final category = _getWorkOutCategory(widget.workOutCategory);

    if ((planC == null) || (category == null) || !isValidCred) {
      _webLaunchStatus.value = WebViewLaunchStatus.error;
      return;
    }
    postData = {
      "userId": userId,
      "planC": planC,
      "category": category,
      "company": companyName,
      "key": apiKey,
    };
    _webLaunchStatus.value = WebViewLaunchStatus.success;
  }

  bool isValidCredentials({
    required String userId,
    required String companyName,
    required String apiKey,
  }) {
    final validUserId = containsDisallowedCharacters(userId);
    final validCompanyName = containsDisallowedCharacters(companyName);
    final validApiKey = containsDisallowedCharacters(apiKey);

    return !(validApiKey) || !(validUserId) || !(validCompanyName);
  }

  String? _getPlanCategory(PlanCategory category) {
    return switch (category) {
      StrengthPlanCategory() => StrengthPlanCategory().toString(),
      CardioPlanCategory() => CardioPlanCategory().toString(),
      WeightManagementPlanCategory() =>
          WeightManagementPlanCategory().toString(),
      RehabilitationPlanCategory() => RehabilitationPlanCategory().toString(),

    /// [Should make it as Failure]
      CustomPlanCategory() => category.description.isEmpty
          ? 'planCategory cannot be empty'
          : (containsDisallowedCharacters(category.description)
          ? "planCategory contains disallowed characters: < >, { }, ( ), [ ], ;, \", ', \$, ., #, or <script>"
          : null)
    };
  }

  String? _getWorkOutCategory(WorkOutCategory category) {
    return switch (category) {
      FitnessWorkOutCategory() => FitnessWorkOutCategory().toString(),
      RehabilitationWorkOutCategory() =>
          RehabilitationWorkOutCategory().toString(),

    /// [Should make it as Failure]
      CustomWorkOutCategory() => category.description.isEmpty
          ? 'planCategory cannot be empty'
          : (containsDisallowedCharacters(category.description)
          ? "planCategory contains disallowed characters: < >, { }, ( ), [ ], ;, \", ', \$, ., #, or <script>"
          : null)
    };
  }

  void _sendDataToWebView() async {
    if (_controller != null) {
      await _controller!.evaluateJavascript(
          source:
          "window.postMessage(${jsonEncode(postData)}, 'https://kineste-x-w.vercel.app/');");
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
  }

  void handleMessage(String message) {
    var parsedMessage = jsonDecode(message);
    widget.onHandleMessage.call(parsedMessage);
  }

  bool containsDisallowedCharacters(String str) {
    final regx = [
      '<',
      '>',
      '{',
      '}',
      '(',
      ')',
      '[',
      ']',
      ';',
      '"',
      '\'',
      '\$',
      '.',
      '#',
      '<',
      '>',
    ];

    return str.characters.any((el) => regx.contains(el));
  }
}
