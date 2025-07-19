class ContainerLevels {
  final int foodLevel;
  final int phSolutionLevel;

  ContainerLevels({
    required this.foodLevel,
    required this.phSolutionLevel,
  });

  factory ContainerLevels.fromFirestore(Map<String, dynamic> data) {
    return ContainerLevels(
      foodLevel: data['foodLevel'] is int
          ? data['foodLevel']
          : int.tryParse(data['foodLevel'].toString()) ?? 0,
      phSolutionLevel: data['phSolutionLevel'] is int
          ? data['phSolutionLevel']
          : int.tryParse(data['phSolutionLevel'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodLevel': foodLevel,
      'phSolutionLevel': phSolutionLevel,
    };
  }

  @override
  String toString() =>
      'ContainerLevels(foodLevel: $foodLevel, phSolutionLevel: $phSolutionLevel)';
}
