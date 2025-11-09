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
  final disallowedPattern = RegExp(r'<script>|</script>|[<>{}\[\];"\$\.\#]');
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
