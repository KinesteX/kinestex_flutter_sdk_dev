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

  /// Main view URL
  String get mainView => baseUrl;

  /// Plan view URL with encoded plan name
  String planView(String planName) => '$baseUrl/plan/${_encodePath(planName)}';

  /// Workout view URL with encoded workout name
  String workoutView(String workoutName) =>
      '$baseUrl/workout/${_encodePath(workoutName)}';

  /// Experience view URL with encoded experience name
  String experienceView(String experience) =>
      '$baseUrl/experiences/${_encodePath(experience)}';

  /// Personalized plan view URL
  String get personalizedPlanView => '$baseUrl/personalized-plan';

  /// Challenge view URL
  String get challengeView => '$baseUrl/challenge';

  /// Leaderboard view URL with optional username
  String leaderboardView(String username) {
    if (username.isEmpty) {
      return '$baseUrl/leaderboard';
    }
    return '$baseUrl/leaderboard?username=${_encodePath(username)}';
  }

  /// Camera view URL
  String get cameraView => '$baseUrl/camera';

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
