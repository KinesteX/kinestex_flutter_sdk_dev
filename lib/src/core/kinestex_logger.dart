import 'package:flutter/material.dart';

class KinesteXLogger {
  static final KinesteXLogger instance = KinesteXLogger._();
  KinesteXLogger._();

  void _print(String emoji, String message) {
    // Print with your own tag — visible, but clearly separate
    debugPrint('[KinesteX] $emoji $message');
  }

  void info(String message) => _print('ℹ️', 'KinesteX: $message');
  void success(String message) => _print('✅', 'KinesteX: $message');
  void error(String message, [Object? e]) =>
      _print('⚠️', 'KinesteX: $message - $e');
}
