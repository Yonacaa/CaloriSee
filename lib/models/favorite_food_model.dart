class FavoriteFoodModel {
  final int id;
  final int userId;
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final DateTime createdAt;

  FavoriteFoodModel({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.createdAt,
  });

  // Convert from database map
  factory FavoriteFoodModel.fromMap(Map<String, dynamic> map) {
    return FavoriteFoodModel(
      id: map['id'] as int,
      userId: map['userId'] as int,
      foodName: map['foodName'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'FavoriteFoodModel(id: $id, foodName: $foodName, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs)';
}
