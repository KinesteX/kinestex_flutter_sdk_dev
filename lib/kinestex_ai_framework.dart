import 'dart:developer';
import 'package:flutter/material.dart';
import 'generic_web_view.dart';
import 'kinestex_sdk.dart';

class KinesteXAIFramework {
  static Widget createMainView({
    required String apiKey,
    required String companyName,
    required String userId,
    PlanCategory planCategory = PlanCategory.Cardio,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived
  }) {
    final validationError = _validateInput(
      apiKey: apiKey,
      companyName: companyName,
      userId: userId,
      planCategory: planCategory,
    );

    if (validationError != null) {
      print("KinesteX SDK: ⚠️ Validation Error: $validationError");
      return Container();
    } else {
      final data = <String, dynamic>{
        'planC': planCategoryString(planCategory),

        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },

      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          userId: userId,
          url: "https://kinestex.vercel.app",
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived,
          showKinesteX: isShowKinestex
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createPlanView({
    required String apiKey,
    required String companyName,
    required String userId,
    required String planName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(planName)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or planName contains disallowed characters");
      return Container();
    } else {
      final adjustedPlanName = planName.replaceAll(' ', '%20');
      final url = "https://kinestex.vercel.app/plan/$adjustedPlanName";
      final data = <String, dynamic>{
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createExperienceView({
    required String apiKey,
    required String companyName,
    required String userId,
    required String experience,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(experience)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or planName contains disallowed characters");
      return Container();
    } else {
      final adjustedExperience = experience.replaceAll(' ', '%20');
      final url = "https://kinestex.vercel.app/experiences/$adjustedExperience";
      final data = <String, dynamic>{
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createPersonalizedPlanView({
    required String apiKey,
    required String companyName,
    required String userId,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, or userId, contains disallowed characters");
      return Container();
    } else {
      const url = "https://kinestex.vercel.app/personalized-plan";
      final data = <String, dynamic>{
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
      );
    }
  }

  static Widget createAdminWorkoutEditor({
    required String apiKey,
    required String companyName,
    required String userId,
    required String organization,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) || containsDisallowedCharacters(organization)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or/and organization contain disallowed characters");
      return Container();
    } else {
      const url = "https://admin.kinestex.com/main?isCustomAuth=true&hideSidebar=true&hidePlansTab=true&tab=workouts";
      final data = <String, dynamic>{
          'organization': organization,
          'apiKey': apiKey,
          'companyName': companyName,
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
      );
    }
  }


  static Widget createWorkoutView({
    required String apiKey,
    required String companyName,
    required String userId,
    required String workoutName,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(workoutName)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or workoutName contains disallowed characters");
      return Container();
    } else {
      final adjustedWorkoutName = workoutName.replaceAll(' ', '%20');
      final url = "https://kinestex.vercel.app/workout/$adjustedWorkoutName";
      final data = <String, dynamic>{
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createChallengeView({
    required String apiKey,
    required String companyName,
    required String userId,
    String exercise = "Squats",
    required int countdown,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    bool showLeaderboard = true,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(exercise)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or exercise contains disallowed characters");
      return Container();
    } else {
      final data = <String, dynamic>{
        'exercise': exercise,
        'countdown': countdown,
        'showLeaderboard': showLeaderboard,
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      return GenericWebView(
          apiKey: apiKey,
          showKinesteX: isShowKinestex,
          companyName: companyName,
          userId: userId,
          url: "https://kinestex.vercel.app/challenge",
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createLeaderboardView({
    required String apiKey,
    required String companyName,
    required String userId,
    String exercise = "Squats",
    username = "",
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isShowKinestex,
    required ValueNotifier<bool> isLoading,
    required Function(WebViewMessage) onMessageReceived
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(exercise) ||
    containsDisallowedCharacters(username)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, exercise, or/and username contains disallowed characters");
      return Container();
    } else {
      final data = <String, dynamic>{
        'exercise': exercise,
      };

      validateCustomParams(customParams, data);

      final adjustedUserName = username.replaceAll(' ', '%20');
      var url = "https://kinestex.vercel.app/leaderboard";
      if (username.isNotEmpty) url = "https://kinestex.vercel.app/leaderboard?username=$adjustedUserName";


      return GenericWebView(
          apiKey: apiKey,
          showKinesteX: isShowKinestex,
          companyName: companyName,
          userId: userId,
          url: url,
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static Widget createCameraComponent({
    required String apiKey,
    required String companyName,
    required String userId,
    required List<String> exercises,
    required String currentExercise,
    UserDetails? user,
    Map<String, dynamic>? customParams,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isShowKinestex,
    required Function(WebViewMessage) onMessageReceived,
    String? updatedExercise,
  }) {
    for (final exercise in exercises) {
      if (containsDisallowedCharacters(exercise)) {
        print("KinesteX SDK: ⚠️ Validation Error: $exercise contains disallowed characters");
        return Container();
      }
    }

    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId) ||
        containsDisallowedCharacters(currentExercise)) {
      print(
          "KinesteX SDK: ⚠️ Validation Error: apiKey, companyName, userId, or currentExercise contains disallowed characters");
      return Container();
    } else {
      final data = <String, dynamic>{
        'exercises': exercises,
        'currentExercise': currentExercise,
        if (user != null) ...{
          'age': user.age,
          'height': user.height,
          'weight': user.weight,
          'gender': genderString(user.gender),
          'lifestyle': lifestyleString(user.lifestyle),
        },
      };

      validateCustomParams(customParams, data);

      log("KinesteX SDK: Updated exercise:  ${updatedExercise}");
      return GenericWebView(
          apiKey: apiKey,
          companyName: companyName,
          showKinesteX: isShowKinestex,
          userId: userId,
          url: "https://kinestex.vercel.app/camera",
          data: data,
          isLoading: isLoading,
          onMessageReceived: onMessageReceived,
          updatedExercise: updatedExercise
        // isHideHeaderMain: isHideHeaderMain, // Pass the parameter
      );
    }
  }

  static void validateCustomParams(
      Map<String, dynamic>? customParams, Map<String, dynamic> data) {
    if (customParams != null) {
      customParams.forEach((key, value) {
        if (containsDisallowedCharacters(key) ||
            (value is String && containsDisallowedCharacters(value))) {
          print('KinesteX SDK: ⚠️ Validation Error: Custom parameter key or value contains disallowed characters');
        } else {
          data[key] = value;
        }
      });
    }
  }

  static String? _validateInput({
    required String apiKey,
    required String companyName,
    required String userId,
    required PlanCategory planCategory,
  }) {
    if (containsDisallowedCharacters(apiKey) ||
        containsDisallowedCharacters(companyName) ||
        containsDisallowedCharacters(userId)) {
      return "apiKey, companyName, or userId contains disallowed characters";
    }
    if (planCategory == PlanCategory.Custom &&
        (planCategoryString(planCategory).isEmpty ||
            containsDisallowedCharacters(planCategoryString(planCategory)))) {
      return "planCategory is invalid";
    }
    return null;
  }
}
