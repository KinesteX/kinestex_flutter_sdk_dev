import 'package:flutter/material.dart';
import 'package:kinestex_sdk_flutter/kinestex_sdk.dart';
import 'package:kinestex_sdk_flutter/src/core/generic_web_view.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';

class KinesteXViewBuilder {
  static Widget build({
    required String apiKey,
    required String companyName,
    required String userId,
    required String url,
    IStyle? style,
    Map<String, dynamic> data = const {},
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> showKinesteX,
    required Function(WebViewMessage) onMessageReceived,
    String? updatedExercise,
  }) {
    // Step 1: Validate core parameters
    if (!_validateCoreParams(apiKey, companyName, userId)) {
      return Container();
    }

    // Step 2: Build final data map
    final finalData = Map<String, dynamic>.from(data);
    _addUserDetails(finalData, user);
    _addCustomStyle(finalData, style);
    _mergeCustomParams(finalData, customParams);

    // Step 3: Determine overlay color from customParams
    final overlayColor = (style?.loadingBackgroundColor?.isNotEmpty ?? false)
        ? colorFromHex(style!.loadingBackgroundColor!)
        : Colors.black;

    // Step 4: Create and return the WebView widget
    return GenericWebView(
      apiKey: apiKey,
      companyName: companyName,
      userId: userId,
      url: url,
      data: finalData,
      overlayColor: overlayColor,
      isLoading: isLoading,
      showKinesteX: showKinesteX,
      onMessageReceived: onMessageReceived,
      updatedExercise: updatedExercise,
    );
  }

  /// Validates that core parameters don't contain disallowed characters
  ///
  /// Checks apiKey, companyName, and userId for security issues.
  /// Logs error and returns false if validation fails.
  static bool _validateCoreParams(
    String apiKey,
    String company,
    String userId,
  ) {
    final logger = KinesteXLogger.instance;
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(company) ||
        containsDisallowedCharacters(userId)) {
      logger.error(
        'API key, company name, or user ID contains disallowed characters',
      );
      return false;
    }
    return true;
  }

  /// Adds user details to the data map if user is provided
  ///
  /// Maps [UserDetails] properties to the format expected by the WebView:
  /// - age, height, weight (numeric values)
  /// - gender (string: "Male", "Female", "Unknown")
  /// - lifestyle (string: "Sedentary", "Active", etc.)
  static void _addUserDetails(
    Map<String, dynamic> data,
    UserDetails? user,
  ) {
    if (user == null) return;

    data.addAll({
      'age': user.age,
      'height': user.height,
      'weight': user.weight,
      'gender': genderString(user.gender),
      'lifestyle': lifestyleString(user.lifestyle),
    });
  }

  static void _addCustomStyle(
    Map<String, dynamic> data,
    IStyle? style,
  ) {
    final logger = KinesteXLogger.instance;

    if (style == null) return;

    // data["style"] = style.toJson();

    for (final entry in style.toJson().entries) {
      final key = entry.key;
      final value = entry.value;

      // Validate key
      if (containsDisallowedCharacters(key)) {
        logger.error(
            'Custom parameter key "$key" contains disallowed characters');
        continue;
      }

      // Validate string values
      if (value is String && containsDisallowedCharacters(value)) {
        logger.error(
            'Custom parameter "$key" value contains disallowed characters');
        continue;
      }

      // Add valid parameter
      data[key] = value;
    }
  }

  /// Merges custom parameters into data map with validation
  ///
  /// Validates each custom parameter key and value for security.
  /// Only adds parameters that pass validation.
  /// Logs warning for invalid parameters but continues processing.
  static void _mergeCustomParams(
    Map<String, dynamic> data,
    Map<String, dynamic>? customParams,
  ) {
    final logger = KinesteXLogger.instance;

    if (customParams == null) return;

    for (final entry in customParams.entries) {
      final key = entry.key;
      final value = entry.value;

      // Validate key
      if (containsDisallowedCharacters(key)) {
        logger.error(
            'Custom parameter key "$key" contains disallowed characters');
        continue;
      }

      // Validate string values
      if (value is String && containsDisallowedCharacters(value)) {
        logger.error(
            'Custom parameter "$key" value contains disallowed characters');
        continue;
      }

      // Add valid parameter
      data[key] = value;
    }
  }

  static Color colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');

    // If the string has only RGB (6 chars), add full opacity (FF)
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.parse(hex, radix: 16));
  }
}
