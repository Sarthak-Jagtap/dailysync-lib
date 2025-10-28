class WorkoutLog {
  final String id;
  final String workoutName;
  final int durationInMinutes;
  final int caloriesBurned;
  final DateTime date;

  WorkoutLog({
    required this.id,
    required this.workoutName,
    required this.durationInMinutes,
    required this.caloriesBurned,
    required this.date,
  });

  // This will be useful when you integrate a database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutName': workoutName,
      'durationInMinutes': durationInMinutes,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
    };
  }
}
