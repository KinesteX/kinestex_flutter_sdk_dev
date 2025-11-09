import 'package:flutter/foundation.dart';

@immutable
abstract class WebViewMessage {
  final Map<String, dynamic> data;

  const WebViewMessage(this.data);

  factory WebViewMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'kinestex_launched':
        return KinestexLaunched(json);
      case 'finished_workout':
        return FinishedWorkout(json);
      case 'error_occurred':
        return ErrorOccurred(json);
      case 'exercise_completed':
        return ExerciseCompleted(json);
      case 'exit_kinestex':
        return ExitKinestex(json);
      case 'workout_opened':
        return WorkoutOpened(json);
      case 'workout_started':
        return WorkoutStarted(json);
      case 'plan_unlocked':
        return PlanUnlocked(json);
      case 'mistake':
        return Mistake(json);
      case 'successful_repeat':
        return Reps(json);
      case 'left_camera_frame':
        return LeftCameraFrame(json);
      case 'returned_camera_frame':
        return ReturnedCameraFrame(json);
      case 'workout_overview':
        return WorkoutOverview(json);
      case 'exercise_overview':
        return ExerciseOverview(json);
      case 'workout_completed':
        return WorkoutCompleted(json);
      default:
        return CustomType(json);
    }
  }
}

class KinestexLaunched extends WebViewMessage {
  const KinestexLaunched(Map<String, dynamic> data) : super(data);
}

class FinishedWorkout extends WebViewMessage {
  FinishedWorkout(Map<String, dynamic> data) : super(data);
}

class ErrorOccurred extends WebViewMessage {
  ErrorOccurred(Map<String, dynamic> data) : super(data);
}

class ExerciseCompleted extends WebViewMessage {
  ExerciseCompleted(Map<String, dynamic> data) : super(data);
}

class ExitKinestex extends WebViewMessage {
  ExitKinestex(Map<String, dynamic> data) : super(data);
}

class WorkoutOpened extends WebViewMessage {
  WorkoutOpened(Map<String, dynamic> data) : super(data);
}

class WorkoutStarted extends WebViewMessage {
  WorkoutStarted(Map<String, dynamic> data) : super(data);
}

class PlanUnlocked extends WebViewMessage {
  PlanUnlocked(Map<String, dynamic> data) : super(data);
}

class CustomType extends WebViewMessage {
  CustomType(Map<String, dynamic> data) : super(data);
}

class Reps extends WebViewMessage {
  Reps(Map<String, dynamic> data) : super(data);
}

class Mistake extends WebViewMessage {
  Mistake(Map<String, dynamic> data) : super(data);
}

class LeftCameraFrame extends WebViewMessage {
  LeftCameraFrame(Map<String, dynamic> data) : super(data);
}

class ReturnedCameraFrame extends WebViewMessage {
  ReturnedCameraFrame(Map<String, dynamic> data) : super(data);
}

class WorkoutOverview extends WebViewMessage {
  WorkoutOverview(Map<String, dynamic> data) : super(data);
}

class ExerciseOverview extends WebViewMessage {
  ExerciseOverview(Map<String, dynamic> data) : super(data);
}

class WorkoutCompleted extends WebViewMessage {
  WorkoutCompleted(Map<String, dynamic> data) : super(data);
}