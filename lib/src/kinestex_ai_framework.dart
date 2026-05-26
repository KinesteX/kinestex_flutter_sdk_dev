import 'package:flutter/material.dart';
import 'package:kinestex_sdk_flutter/src/api/api_service.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_credentials.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_initializer.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';
import 'core/kinestex_view_builder.dart';
import 'core/url_helper.dart';
import 'core/generic_web_view.dart';
import '../kinestex_sdk.dart';

/// Entry point for the KinesteX AI SDK.
///
/// Call [initialize] once with your credentials, then use the `create*View`
/// factories to embed KinesteX experiences, or [sendAction] to control an
/// active session.
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
    PlanCategory planCategory = PlanCategory.Cardio,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;
    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.mainView(style: style),
      style: style,
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
    required String planName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.planView(planName, style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a view for a specific workout
  static Widget createWorkoutView({
    required String workoutName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.workoutView(workoutName, style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a view for AI experiences
  static Widget createExperienceView({
    required String experience,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.experienceView(experience, style: style),
      user: user,
      customParams: customParams,
      style: style,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a personalized workout plan view
  static Widget createPersonalizedPlanView({
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.personalizedPlanView(style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a challenge view for specific exercises
  static Widget createChallengeView({
    String exercise = "Squats",
    required int countdown,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    bool showLeaderboard = true,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.challengeView(style: style),
      style: style,
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
    String exercise = "Squats",
    String username = "",
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.leaderboardView(username, style: style),
      style: style,
      data: {'exercise': exercise},
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a custom view
  static Widget createCustomView({
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.mainView(style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a camera component for real-time exercise tracking
  static Widget createCameraComponent({
    required List<String> exercises,
    required String currentExercise,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
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

    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.cameraView(style: style),
      style: style,
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

  /// Creates a view for custom workouts
  static Widget createCustomWorkoutView({
    required List<WorkoutSequenceExercise> customWorkouts,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    // Normalize and validate custom workout exercises
    final normalized = normalizeWorkoutExercises(customWorkouts);
    if (normalized == null) {
      _logger.error(
          'Validation Error: No valid exercises provided for custom workout');
      return Container();
    }

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.customWorkout(style: style),
      style: style,
      data: {
        'customWorkoutExercises': normalized,
      },
      user: user,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a trainer chat view
  ///
  /// Maps to ai.kinestex.com/trainer
  static Widget createTrainerChatView({
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.trainerView(style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates a custom component view for a given route
  ///
  /// Maps to ai.kinestex.com/{route}
  static Widget createCustomComponentView({
    required String route,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    IStyle? style,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    if (containsDisallowedCharacters(route)) {
      _logger.error(
        'Validation Error: route contains disallowed characters',
      );
      return Container();
    }

    final creds = _credentials.credentials;

    return KinesteXViewBuilder.build(
      apiKey: creds.apiKey,
      companyName: creds.companyName,
      userId: creds.userId,
      url: _urlHelper.customComponentView(route, style: style),
      user: user,
      style: style,
      customParams: customParams,
      isLoading: isLoading,
      showKinesteX: isShowKinestex,
      onMessageReceived: onMessageReceived,
    );
  }

  /// Creates an admin workout editor view
  static Widget createAdminWorkoutEditor({
    required String organization,
    Map<String, dynamic>? customParams,
    Map<String, dynamic>? customQueries,
    IStyle? style,
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

    final creds = _credentials.credentials;

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
      style: style,
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

  /// Send a custom action to the WebView
  ///
  /// Used for controlling workout flow:
  /// - Start: `KinesteXAIFramework.sendAction("workout_activity_action", "start")`
  static Future<void> sendAction(String action, String value) async {
    await GenericWebView.controller.sendAction(action, value);
  }
}
