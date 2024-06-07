
sealed class PlanCategory {}

class CardioPlanCategory extends PlanCategory {
  @override
  String toString() {
    return 'Cardio';
  }
}

class StrengthPlanCategory extends PlanCategory {
  @override
  String toString() {
    return 'Strength';
  }
}

class RehabilitationPlanCategory extends PlanCategory {
  @override
  String toString() {
    return 'Rehabilitation';
  }
}

class WeightManagementPlanCategory extends PlanCategory {
  @override
  String toString() {
    return 'Weight Management';
  }
}

class CustomPlanCategory extends PlanCategory {
  final String description;

  CustomPlanCategory(this.description);

  @override
  String toString() {
    return description;
  }
}
