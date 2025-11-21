class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String? fullName;
  final double? weight;
  final double? height;
  final double targetCalories;
  final double targetProtein;
  final double targetFat;
  final double targetCarbs;
  final String? profileImage;
  final String? createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
    this.weight,
    this.height,
    this.targetCalories = 2000.0,
    this.targetProtein = 100.0,
    this.targetFat = 70.0,
    this.targetCarbs = 250.0,
    this.profileImage,
    this.createdAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'weight': weight,
      'height': height,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetFat': targetFat,
      'targetCarbs': targetCarbs,
      'profileImage': profileImage,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      fullName: map['fullName'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      targetCalories: map['targetCalories']?.toDouble() ?? 2000.0,
      targetProtein: map['targetProtein']?.toDouble() ?? 100.0,
      targetFat: map['targetFat']?.toDouble() ?? 70.0,
      targetCarbs: map['targetCarbs']?.toDouble() ?? 250.0,
      profileImage: map['profileImage'],
      createdAt: map['createdAt'],
    );
  }

  // Calculate BMI
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      double heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI Category
  String get bmiCategory {
    if (bmi == null) return 'Data tidak lengkap';
    if (bmi! < 18.5) return 'Kurus';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Gemuk';
    return 'Obesitas';
  }

  // Get BMI Color
  String get bmiColorCode {
    if (bmi == null) return '#9CA3AF';
    if (bmi! < 18.5) return '#3B82F6';
    if (bmi! < 25) return '#10B981';
    if (bmi! < 30) return '#F59E0B';
    return '#EF4444';
  }

  // Copy with
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    double? weight,
    double? height,
    double? targetCalories,
    double? targetProtein,
    double? targetFat,
    double? targetCarbs,
    String? profileImage,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}