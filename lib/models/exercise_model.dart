class ExerciseModel {
  final int? id;
  final int userId;
  final String exerciseName;
  final double caloriesBurned;
  final int durationMinutes;
  final DateTime date;

  ExerciseModel({
    this.id,
    required this.userId,
    required this.exerciseName,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'exerciseName': exerciseName,
      'caloriesBurned': caloriesBurned,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'],
      userId: map['userId'],
      exerciseName: map['exerciseName'],
      caloriesBurned: map['caloriesBurned'],
      durationMinutes: map['durationMinutes'],
      date: DateTime.parse(map['date']),
    );
  }
}
