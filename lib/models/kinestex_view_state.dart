import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class KinesteXViewState extends ChangeNotifier {
  InAppWebViewController? _webViewController;

  InAppWebViewController? get webViewController => _webViewController;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    notifyListeners();
  }

  void clearWebViewController() {
    _webViewController = null;
    notifyListeners();
  }
}