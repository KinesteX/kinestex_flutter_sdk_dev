import 'package:flutter/foundation.dart';

// MARK: - Enums

/// ContentType defines the types of content that can be fetched from the API
enum ContentType {
  workout('Workout'),
  plan('Plan'),
  exercise('Exercise');

  final String value;
  const ContentType(this.value);

  @override
  String toString() => value;
}

enum FilterType {
  none('None'),
  category('Category'),
  bodyParts('Body Parts');

  final String value;
  const FilterType(this.value);

  @override
  String toString() => value;
}

enum SearchType {
  findById('Find By ID'),
  findByTitle('Find By Title');

  final String value;
  const SearchType(this.value);

  @override
  String toString() => value;
}

/// BodyPart defines the different body parts that can be targeted by exercises
enum BodyPart {
  abs('Abs'),
  biceps('Biceps'),
  calves('Calves'),
  chest('Chest'),
  externalOblique('External Oblique'),
  forearms('Forearms'),
  glutes('Glutes'),
  neck('Neck'),
  quads('Quads'),
  shoulders('Shoulders'),
  triceps('Triceps'),
  hamstrings('Hamstrings'),
  lats('Lats'),
  lowerBack('Lower Back'),
  traps('Traps'),
  fullBody('Full Body');

  final String value;
  const BodyPart(this.value);

  @override
  String toString() => value;
}

// MARK: - Base Models

/// EquipmentModel represents an equipment item used in workouts and exercises
@immutable
class EquipmentModel {
  final int id;
  final String title;
  final String description;
  final String homeAlternative;
  final String thumbnailUrl;

  const EquipmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.homeAlternative,
    required this.thumbnailUrl,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      homeAlternative: json['home_alternative']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
    );
  }
}

/// Safely parses a list of equipment JSON objects, skipping invalid entries
List<EquipmentModel> _parseEquipmentList(List<dynamic>? equipmentJson) {
  if (equipmentJson == null) return [];
  return equipmentJson
      .whereType<Map<String, dynamic>>()
      .where((e) {
        final title = e['title'];
        return title != null && title.toString().isNotEmpty;
      })
      .map((e) => EquipmentModel.fromJson(e))
      .toList();
}

/// WorkoutModel represents the structure of a workout returned by the API
@immutable
class WorkoutModel {
  final String id;
  final String title;
  final String imgURL;
  final String? category;
  final String description;
  final int? totalMinutes;
  final int? totalCalories;
  final List<String> bodyParts;
  final String? difficultyLevel;
  final List<EquipmentModel> equipment;
  final List<ExerciseModel> sequence;
  final Map<String, dynamic>? rawJSON;

  const WorkoutModel({
    required this.id,
    required this.title,
    required this.imgURL,
    this.category,
    required this.description,
    this.totalMinutes,
    this.totalCalories,
    required this.bodyParts,
    this.difficultyLevel,
    this.equipment = const [],
    required this.sequence,
    this.rawJSON,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imgURL: json['workout_desc_img'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String? ?? '',
      totalMinutes: json['total_minutes'] as int?,
      totalCalories: json['calories'] as int?,
      bodyParts: (json['body_parts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      difficultyLevel: json['dif_level'] as String?,
      equipment: _parseEquipmentList(json['equipment'] as List<dynamic>?),
      sequence: (json['sequence'] as List<dynamic>?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rawJSON: json,
    );
  }
}

/// ExerciseModel represents the details of an exercise
@immutable
class ExerciseModel {
  final String id;
  final String title;
  final String thumbnailURL;
  final String videoURL;
  final String maleVideoURL;
  final String maleThumbnailURL;
  final int? workoutCountdown;
  final int? workoutReps;
  final int? averageReps;
  final int? averageCountdown;
  final int restDuration;
  final String restSpeech;
  final String restSpeechText;
  final double? averageCalories;
  final List<String> bodyParts;
  final List<EquipmentModel> equipment;
  final String description;
  final String difficultyLevel;
  final String commonMistakes;
  final List<String> steps;
  final String tips;
  final String modelId;
  final Map<String, dynamic>? rawJSON;

  const ExerciseModel({
    required this.id,
    required this.title,
    required this.thumbnailURL,
    required this.videoURL,
    required this.maleVideoURL,
    required this.maleThumbnailURL,
    this.workoutCountdown,
    this.workoutReps,
    this.averageReps,
    this.averageCountdown,
    required this.restDuration,
    required this.restSpeech,
    required this.restSpeechText,
    this.averageCalories,
    required this.bodyParts,
    this.equipment = const [],
    required this.description,
    required this.difficultyLevel,
    required this.commonMistakes,
    required this.steps,
    required this.tips,
    required this.modelId,
    this.rawJSON,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String? ?? 'NA',
      title: json['title'] as String? ?? '',
      thumbnailURL: json['thumbnail_URL'] as String? ?? '',
      videoURL: json['video_URL'] as String? ?? '',
      maleVideoURL: json['male_video_URL'] as String? ?? 'NA',
      maleThumbnailURL: json['male_thumbnail_URL'] as String? ?? 'NA',
      workoutCountdown: json['workout_countdown'] as int?,
      workoutReps: json['workout_reps'] as int?,
      averageReps: json['avg_reps'] as int?,
      averageCountdown: json['avg_countdown'] as int?,
      restDuration: json['rest_duration'] as int? ?? 10,
      restSpeech: json['rest_speech'] as String? ?? '',
      restSpeechText: json['rest_speech_text'] as String? ?? '',
      averageCalories: (json['avg_cal'] as num?)?.toDouble(),
      bodyParts: (json['body_parts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      equipment: _parseEquipmentList(json['equipment'] as List<dynamic>?),
      description:
          json['description'] as String? ?? 'Missing exercise description',
      difficultyLevel: json['dif_level'] as String? ?? 'Medium',
      commonMistakes: json['common_mistakes'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tips: json['tips'] as String? ?? '',
      modelId: json['model_id'] as String? ?? 'NA',
      rawJSON: json,
    );
  }
}

/// PlanModel represents a workout plan
@immutable
class PlanModel {
  final String id;
  final String imgURL;
  final String title;
  final PlanModelCategory category;
  final Map<String, PlanLevel> levels;
  final String createdBy;
  final Map<String, dynamic>? rawJSON;

  const PlanModel({
    required this.id,
    required this.imgURL,
    required this.title,
    required this.category,
    required this.levels,
    required this.createdBy,
    this.rawJSON,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final levelsMap = <String, PlanLevel>{};
    final levelsJson = json['levels'] as Map<String, dynamic>?;
    levelsJson?.forEach((key, value) {
      levelsMap[key] = PlanLevel.fromJson(value as Map<String, dynamic>);
    });

    return PlanModel(
      id: json['id'] as String? ?? '',
      imgURL: json['img_URL'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category:
          PlanModelCategory.fromJson(json['category'] as Map<String, dynamic>),
      levels: levelsMap,
      createdBy: json['created_by'] as String? ?? '',
      rawJSON: json,
    );
  }
}

/// PlanModelCategory defines a category within a workout plan
@immutable
class PlanModelCategory {
  final String description;
  final Map<String, int> levels;
  final Map<String, dynamic>? rawJSON;

  const PlanModelCategory({
    required this.description,
    required this.levels,
    this.rawJSON,
  });

  factory PlanModelCategory.fromJson(Map<String, dynamic> json) {
    return PlanModelCategory(
      description: json['description'] as String? ?? '',
      levels: (json['levels'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      rawJSON: json,
    );
  }
}

/// PlanLevel defines a specific level within a workout plan
@immutable
class PlanLevel {
  final String title;
  final String description;
  final Map<String, PlanDay> days;
  final Map<String, dynamic>? rawJSON;

  const PlanLevel({
    required this.title,
    required this.description,
    required this.days,
    this.rawJSON,
  });

  factory PlanLevel.fromJson(Map<String, dynamic> json) {
    final daysMap = <String, PlanDay>{};
    final daysJson = json['days'] as Map<String, dynamic>?;
    daysJson?.forEach((key, value) {
      daysMap[key] = PlanDay.fromJson(value as Map<String, dynamic>);
    });

    return PlanLevel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      days: daysMap,
      rawJSON: json,
    );
  }
}

/// PlanDay represents a day within a plan level
@immutable
class PlanDay {
  final String title;
  final String description;
  final List<WorkoutSummary>? workouts;
  final Map<String, dynamic>? rawJSON;

  const PlanDay({
    required this.title,
    required this.description,
    this.workouts,
    this.rawJSON,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      workouts: (json['workouts'] as List<dynamic>?)
          ?.map((e) => WorkoutSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawJSON: json,
    );
  }
}

/// WorkoutSummary provides basic information about a workout
@immutable
class WorkoutSummary {
  final String id;
  final String imgURL;
  final String title;
  final double? calories;
  final int totalMinutes;
  final Map<String, dynamic>? rawJSON;

  const WorkoutSummary({
    required this.id,
    required this.imgURL,
    required this.title,
    this.calories,
    required this.totalMinutes,
    this.rawJSON,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      id: json['id'] as String? ?? '',
      imgURL: json['imgURL'] as String? ?? '',
      title: json['title'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble(),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      rawJSON: json,
    );
  }
}

// MARK: - API Response Models

@immutable
class WorkoutsResponse {
  final List<WorkoutModel> workouts;
  final String lastDocId;
  final Map<String, dynamic>? rawJSON;

  const WorkoutsResponse({
    required this.workouts,
    required this.lastDocId,
    this.rawJSON,
  });

  factory WorkoutsResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutsResponse(
      workouts: (json['workouts'] as List<dynamic>?)
              ?.map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastDocId: json['lastDocId'] as String? ?? '',
      rawJSON: json,
    );
  }
}

@immutable
class ExercisesResponse {
  final List<ExerciseModel> exercises;
  final String lastDocId;
  final Map<String, dynamic>? rawJSON;

  const ExercisesResponse({
    required this.exercises,
    required this.lastDocId,
    this.rawJSON,
  });

  factory ExercisesResponse.fromJson(Map<String, dynamic> json) {
    return ExercisesResponse(
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastDocId: json['lastDocId'] as String? ?? '',
      rawJSON: json,
    );
  }
}

@immutable
class PlansResponse {
  final List<PlanModel> plans;
  final String lastDocId;
  final Map<String, dynamic>? rawJSON;

  const PlansResponse({
    required this.plans,
    required this.lastDocId,
    this.rawJSON,
  });

  factory PlansResponse.fromJson(Map<String, dynamic> json) {
    return PlansResponse(
      plans: (json['plans'] as List<dynamic>?)
              ?.map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastDocId: json['lastDocId'] as String? ?? '',
      rawJSON: json,
    );
  }
}

// MARK: - API Result

/// APIContentResult represents the result of an API request
sealed class APIContentResult {
  const APIContentResult();
}

class WorkoutsResult extends APIContentResult {
  final WorkoutsResponse response;
  const WorkoutsResult(this.response);
}

class WorkoutResult extends APIContentResult {
  final WorkoutModel workout;
  const WorkoutResult(this.workout);
}

class PlansResult extends APIContentResult {
  final PlansResponse response;
  const PlansResult(this.response);
}

class PlanResult extends APIContentResult {
  final PlanModel plan;
  const PlanResult(this.plan);
}

class ExercisesResult extends APIContentResult {
  final ExercisesResponse response;
  const ExercisesResult(this.response);
}

class ExerciseResult extends APIContentResult {
  final ExerciseModel exercise;
  const ExerciseResult(this.exercise);
}

class ErrorResult extends APIContentResult {
  final String message;
  const ErrorResult(this.message);
}

class RawDataResult extends APIContentResult {
  final Map<String, dynamic> data;
  final String? errorMessage;
  const RawDataResult(this.data, [this.errorMessage]);
}
