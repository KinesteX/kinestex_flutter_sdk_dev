import 'package:flutter/material.dart';
import 'package:kinestex_sdk_flutter/src/api/api_service.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_credentials.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_initializer.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';
import 'core/kinestex_view_builder.dart';
import 'core/url_helper.dart';
import '../kinestex_sdk.dart';

class KinesteXAIFramework {
  static const _urlHelper = UrlHelper();
  static final _initializer = KinesteXInitializer();
  static final _credentials = KinesteXCredentials();
  static final _logger = KinesteXLogger.instance;
  static APIService? _apiService;

  /// Get the API service instance for fetching workouts, plans, and exercises
  ///
  /// Throws an exception if initialize() has not been called yet
  static APIService get apiService {
    if (_apiService == null) {
      throw Exception(
          'KinesteX SDK not initialized. Call KinesteXAIFramework.initialize() first.');
    }
    return _apiService!;
  }

  static Future<void> initialize({
    required String apiKey,
    required String companyName,
    required String userId,
  }) async {
    await _initializer.initialize(apiKey, companyName, userId);
    _credentials.set(apiKey, companyName, userId);

    // Initialize API service
    _apiService = APIService(
      apiKey: apiKey,
      companyName: companyName,
    );
    _logger.success('API Service initialized');
  }

  static Future<void> dispose() async {
    await _initializer.dispose();
  }

  /// Creates the main KinesteX view with categorized workout plans
  static Widget createMainView({
    String? apiKey,
    String? companyName,
    String? userId,
    PlanCategory planCategory = PlanCategory.Cardio,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);
    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.mainView,
      data: {
        'planC': planCategoryString(planCategory),
      },
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a view for a specific workout plan
  static Widget createPlanView({
    String? apiKey,
    String? companyName,
    String? userId,
    required String planName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.planView(planName),
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a view for a specific workout
  static Widget createWorkoutView({
    String? apiKey,
    String? companyName,
    String? userId,
    required String workoutName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.workoutView(workoutName),
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a view for AI experiences
  static Widget createExperienceView({
    String? apiKey,
    String? companyName,
    String? userId,
    required String experience,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.experienceView(experience),
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a personalized workout plan view
  static Widget createPersonalizedPlanView({
    String? apiKey,
    String? companyName,
    String? userId,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.personalizedPlanView,
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a challenge view for specific exercises
  static Widget createChallengeView({
    String? apiKey,
    String? companyName,
    String? userId,
    String exercise = "Squats",
    required int countdown,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    bool showLeaderboard = true,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.challengeView,
      data: {
        'exercise': exercise,
        'countdown': countdown,
        'showLeaderboard': showLeaderboard,
      },
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a leaderboard view
  static Widget createLeaderboardView({
    String? apiKey,
    String? companyName,
    String? userId,
    String exercise = "Squats",
    String username = "",
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.leaderboardView(username),
      data: {'exercise': exercise},
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a custom view
  static Widget createCustomView({
    String? apiKey,
    String? companyName,
    String? userId,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.mainView,
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a camera component for real-time exercise tracking
  static Widget createCameraComponent({
    String? apiKey,
    String? companyName,
    String? userId,
    required List<String> exercises,
    required String currentExercise,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
    String? updatedExercise,
  }) {
    // Validate exercises list
    for (final exercise in exercises) {
      if (containsDisallowedCharacters(exercise)) {
        _logger.error(
            'Validation Error: Exercise "$exercise" contains disallowed characters');
        return Container();
      }
    }

    final creds = _credentials.resolve(apiKey, companyName, userId);

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.cameraView,
      data: {
        'exercises': exercises,
        'currentExercise': currentExercise,
      },
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
      updatedExercise: updatedExercise,
    );
  }

  /// Creates an admin workout editor view
  static Widget createAdminWorkoutEditor({
    String? apiKey,
    String? companyName,
    String? userId,
    required String organization,
    Map<String, dynamic>? customParams,
    Map<String, dynamic>? customQueries,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
    AdminContentType? contentType,
    String? contentId,
  }) {
    // Validate organization
    if (containsDisallowedCharacters(organization)) {
      _logger.error(
        'Validation Error: organization contains disallowed characters',
      );
      return Container();
    }

    final creds = _credentials.resolve(apiKey, companyName, userId);

    final url = _urlHelper.adminView(
      contentType: contentType,
      contentId: contentId,
      customQueries: customQueries,
    );

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: url,
      data: {
        'organization': organization,
        'apiKey': creds.apiKey,
        'companyName': creds.companyName,
      },
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }
}
