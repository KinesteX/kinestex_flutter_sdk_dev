import 'dart:convert';

enum PlanCategory { Cardio, WeightManagement, Strength, Rehabilitation, Custom }

enum Gender { Male, Female, Unknown }

enum Lifestyle { Sedentary, SlightlyActive, Active, VeryActive }

enum AdminContentType { workout, plan, exercise }

String segmentFor(AdminContentType type) {
  switch (type) {
    case AdminContentType.workout:
      return 'workouts';
    case AdminContentType.plan:
      return 'plans';
    case AdminContentType.exercise:
      return 'exercises';
  }
}

String planCategoryString(PlanCategory category) {
  switch (category) {
    case PlanCategory.Cardio:
      return "Cardio";
    case PlanCategory.WeightManagement:
      return "Weight Management";
    case PlanCategory.Strength:
      return "Strength";
    case PlanCategory.Rehabilitation:
      return "Rehabilitation";
    case PlanCategory.Custom:
      return "Custom";
  }
}

PlanCategory getPlanCategoryFromString(String category) {
  switch (category.toLowerCase()) {
    case "cardio":
      return PlanCategory.Cardio;
    case "weightmanagement":
    case "weight management":
      return PlanCategory.WeightManagement;
    case "strength":
      return PlanCategory.Strength;
    case "rehabilitation":
      return PlanCategory.Rehabilitation;
    case "custom":
      return PlanCategory.Custom;
    default:
      return PlanCategory.Cardio;
  }
}

String genderString(Gender gender) {
  switch (gender) {
    case Gender.Male:
      return "Male";
    case Gender.Female:
      return "Female";
    case Gender.Unknown:
      return "Male";
  }
}

String lifestyleString(Lifestyle lifestyle) {
  switch (lifestyle) {
    case Lifestyle.Sedentary:
      return "Sedentary";
    case Lifestyle.SlightlyActive:
      return "Slightly Active";
    case Lifestyle.Active:
      return "Active";
    case Lifestyle.VeryActive:
      return "Very Active";
  }
}

bool containsDisallowedCharacters(String input) {
  final disallowedPattern = RegExp(r'<script>|</script>|[<>{}\[\];"\$\#]');
  return disallowedPattern.hasMatch(input);
}

class UserDetails {
  final int age;
  final double height;
  final double weight;
  final Gender gender;
  final Lifestyle lifestyle;

  UserDetails({
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.lifestyle,
  });
}

class IStyle {
  final String style;
  final String? themeName;
  final String? loadingStickmanColor;
  final String? loadingBackgroundColor;
  final String? loadingTextColor;

  IStyle({
    this.style = 'dark',
    this.themeName,
    this.loadingStickmanColor,
    this.loadingBackgroundColor,
    this.loadingTextColor,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['style'] = style;
    if (themeName != null) data['themeName'] = themeName;
    if (loadingStickmanColor != null) {
      data['loadingStickmanColor'] = loadingStickmanColor;
    }
    if (loadingBackgroundColor != null) {
      data['loadingBackgroundColor'] = loadingBackgroundColor;
    }
    if (loadingTextColor != null) {
      data['loadingTextColor'] = loadingTextColor;
    }

    return data;
  }
}

class WorkoutSequenceExercise {
  final String exerciseId;
  final int?
      reps; // number | null -> int? (use int; change to double? if you need fractions)
  final int? duration; // number | null -> int? (e.g. duration in seconds)
  final bool includeRestPeriod;
  final int restDuration; // number -> int (e.g. seconds)

  const WorkoutSequenceExercise({
    required this.exerciseId,
    this.reps,
    this.duration,
    this.includeRestPeriod = false,
    this.restDuration = 0,
  });

  WorkoutSequenceExercise copyWith({
    String? exerciseId,
    int? reps,
    int? duration,
    bool? includeRestPeriod,
    int? restDuration,
  }) {
    return WorkoutSequenceExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      includeRestPeriod: includeRestPeriod ?? this.includeRestPeriod,
      restDuration: restDuration ?? this.restDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'reps': reps,
      'duration': duration,
      'includeRestPeriod': includeRestPeriod,
      'restDuration': restDuration,
    };
  }

  factory WorkoutSequenceExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutSequenceExercise(
      exerciseId: map['exerciseId'] as String,
      reps: map['reps'] != null ? (map['reps'] as num).toInt() : null,
      duration:
          map['duration'] != null ? (map['duration'] as num).toInt() : null,
      includeRestPeriod: map['includeRestPeriod'] == null
          ? false
          : (map['includeRestPeriod'] as bool),
      restDuration: map['restDuration'] != null
          ? (map['restDuration'] as num).toInt()
          : 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkoutSequenceExercise.fromJson(String source) =>
      WorkoutSequenceExercise.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSequenceExercise &&
        other.exerciseId == exerciseId &&
        other.reps == reps &&
        other.duration == duration &&
        other.includeRestPeriod == includeRestPeriod &&
        other.restDuration == restDuration;
  }
}

/// Normalizes and validates a list of workout exercises
///
/// Returns null if the list is empty or all exercises are invalid.
/// Filters out exercises that fail validation.
List<Map<String, dynamic>>? normalizeWorkoutExercises(
  List<WorkoutSequenceExercise>? exercises,
) {
  if (exercises == null || exercises.isEmpty) {
    return null;
  }

  final normalizedExercises = <Map<String, dynamic>>[];

  for (final exercise in exercises) {
    // Validate exerciseId
    if (exercise.exerciseId.isEmpty ||
        containsDisallowedCharacters(exercise.exerciseId)) {
      // Skip invalid exercises
      continue;
    }

    // Validate numeric values
    if ((exercise.reps != null && exercise.reps! < 0) ||
        (exercise.duration != null && exercise.duration! < 0) ||
        exercise.restDuration < 0) {
      // Skip exercises with invalid numeric values
      continue;
    }

    normalizedExercises.add({
      'exerciseId': exercise.exerciseId,
      'reps': exercise.reps,
      'duration': exercise.duration,
      'includeRestPeriod': exercise.includeRestPeriod,
      'restDuration': exercise.restDuration,
    });
  }

  return normalizedExercises.isEmpty ? null : normalizedExercises;
}
