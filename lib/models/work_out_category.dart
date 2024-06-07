sealed class WorkOutCategory {}

class FitnessWorkOutCategory extends WorkOutCategory {
  @override
  String toString() {
    return 'Fitness';
  }
}

class RehabilitationWorkOutCategory extends WorkOutCategory {
  @override
  String toString() {
    return 'Rehabilitation';
  }
}

class CustomWorkOutCategory extends WorkOutCategory {
  final String description;

  CustomWorkOutCategory(this.description);
  @override
  String toString() {
    return description;
  }
}
