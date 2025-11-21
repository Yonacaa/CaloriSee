class FoodModel {
  final int? id;
  final int userId;
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double sugar;
  final String? imagePath;
  final String? scannedAt;

  FoodModel({
    this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.sugar = 0.0,
    this.imagePath,
    this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'sugar': sugar,
      'imagePath': imagePath,
      'scannedAt': scannedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'],
      userId: map['userId'],
      foodName: map['foodName'],
      calories: map['calories']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      fat: map['fat']?.toDouble() ?? 0.0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      sugar: map['sugar']?.toDouble() ?? 0.0,
      imagePath: map['imagePath'],
      scannedAt: map['scannedAt'],
    );
  }

  // Get formatted date
  String get formattedDate {
    if (scannedAt == null) return '';
    DateTime date = DateTime.parse(scannedAt!);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Calculate total nutrition percentage
  double get totalNutrition => protein + fat + carbs + sugar;

  // Get nutrition percentages
  double get proteinPercentage => totalNutrition > 0 ? (protein / totalNutrition) * 100 : 0;
  double get fatPercentage => totalNutrition > 0 ? (fat / totalNutrition) * 100 : 0;
  double get carbsPercentage => totalNutrition > 0 ? (carbs / totalNutrition) * 100 : 0;
  double get sugarPercentage => totalNutrition > 0 ? (sugar / totalNutrition) * 100 : 0;
}

// Nutrition Facts from API (for future implementation)
class NutritionFacts {
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;
  final double fiber;
  final double sugar;
  final double sodium;
  final String? imageUrl;

  NutritionFacts({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrates,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.imageUrl,
  });

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      name: json['name'] ?? 'Unknown Food',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      imageUrl: json['image'],
    );
  }
}