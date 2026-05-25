import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';

import '../models/data.dart';

/// Utility class for building KinesteX URLs
///
/// Centralizes all URL construction logic to ensure consistency
/// and proper encoding across the SDK.
class UrlHelper {
  final String baseUrl;
  final String adminUrl;
  static final _logger = KinesteXLogger.instance;

  const UrlHelper({
    this.baseUrl = 'https://ai.kinestex.com',
    this.adminUrl = 'https://admin.kinestex.com',
  });

  /// Builds query string from IStyle (only non-null fields)
  String _buildStyleQuery(IStyle? style) {
    if (style == null) return '';

    final params = <String>[];
    params.add('style=${Uri.encodeComponent(style.style)}');
    if (style.themeName != null) {
      params.add('themeName=${Uri.encodeComponent(style.themeName!)}');
    }
    if (style.loadingStickmanColor != null) {
      params.add(
          'loadingStickmanColor=${Uri.encodeComponent(style.loadingStickmanColor!)}');
    }
    if (style.loadingBackgroundColor != null) {
      params.add(
          'loadingBackgroundColor=${Uri.encodeComponent(style.loadingBackgroundColor!)}');
    }
    if (style.loadingTextColor != null) {
      params.add(
          'loadingTextColor=${Uri.encodeComponent(style.loadingTextColor!)}');
    }

    return params.isEmpty ? '' : params.join('&');
  }

  /// Appends style query to URL
  String _appendStyleQuery(String url, IStyle? style) {
    final query = _buildStyleQuery(style);
    if (query.isEmpty) return url;
    return url.contains('?') ? '$url&$query' : '$url?$query';
  }

  /// Main view URL
  String mainView({IStyle? style}) => _appendStyleQuery(baseUrl, style);

  /// Plan view URL with encoded plan name
  String planView(String planName, {IStyle? style}) =>
      _appendStyleQuery('$baseUrl/plan/${_encodePath(planName)}', style);

  /// Workout view URL with encoded workout name
  String workoutView(String workoutName, {IStyle? style}) =>
      _appendStyleQuery('$baseUrl/workout/${_encodePath(workoutName)}', style);

  /// Custom Workout view
  String customWorkout({IStyle? style}) =>
      _appendStyleQuery('$baseUrl/custom-workout', style);

  /// Experience view URL with encoded experience name
  String experienceView(String experience, {IStyle? style}) =>
      _appendStyleQuery(
          '$baseUrl/experiences/${_encodePath(experience)}', style);

  /// Personalized plan view URL
  String personalizedPlanView({IStyle? style}) =>
      _appendStyleQuery('$baseUrl/personalized-plan', style);

  /// Challenge view URL
  String challengeView({IStyle? style}) =>
      _appendStyleQuery('$baseUrl/challenge', style);

  /// Leaderboard view URL with optional username
  String leaderboardView(String username, {IStyle? style}) {
    final base = username.isEmpty
        ? '$baseUrl/leaderboard'
        : '$baseUrl/leaderboard?username=${_encodePath(username)}';
    return _appendStyleQuery(base, style);
  }

  /// Camera view URL
  String cameraView({IStyle? style}) =>
      _appendStyleQuery('$baseUrl/camera', style);

  /// Trainer chat view URL
  String trainerView({IStyle? style}) =>
      _appendStyleQuery('$baseUrl/trainer', style);

  /// Custom component view URL with encoded route
  String customComponentView(String route, {IStyle? style}) =>
      _appendStyleQuery('$baseUrl/${_encodePath(route)}', style);

  /// Admin view URL with complex parameters
  String adminView({
    AdminContentType? contentType,
    String? contentId,
    Map<String, dynamic>? customQueries,
  }) {
    // Validate contentType/contentId pairing
    final hasType = contentType != null;
    final hasId = contentId != null && contentId.isNotEmpty;

    if (hasType != hasId) {
      _logger.error(
        'Validation Error: contentType and contentId must be provided together',
      );
      return adminUrl;
    }

    if (hasId && containsDisallowedCharacters(contentId)) {
      _logger.error(
        'Validation Error: contentId contains disallowed characters',
      );
      return adminUrl;
    }

    // Build path segments
    final pathSegments =
        hasType && hasId ? [segmentFor(contentType), contentId] : ['main'];

    // Build query parameters
    final queryParams = <String, String>{
      'isCustomAuth': 'true',
      'hideSidebar': 'true',
    };

    // Merge customQueries (stringify safely)
    if (customQueries != null && customQueries.isNotEmpty) {
      for (final entry in customQueries.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value == null) continue;
        queryParams[key] = value.toString();
      }
    }

    // Use Uri for proper encoding
    final uri = Uri(
      scheme: 'https',
      host: 'admin.kinestex.com',
      pathSegments: pathSegments,
      queryParameters: queryParams,
    );

    return uri.toString();
  }

  /// Private path encoder - replaces spaces with %20
  String _encodePath(String path) => path.replaceAll(' ', '%20');
}
