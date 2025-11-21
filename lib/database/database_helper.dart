import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calorisee.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        fullName TEXT,
        weight REAL,
        height REAL,
        targetCalories REAL DEFAULT 2000,
        targetProtein REAL DEFAULT 100.0,
        targetFat REAL DEFAULT 70.0,
        targetCarbs REAL DEFAULT 250.0,
        profileImage TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE food_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        foodName TEXT NOT NULL,
        calories REAL,
        protein REAL,
        fat REAL,
        carbs REAL,
        imagePath TEXT,
        scannedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        foodName TEXT NOT NULL,
        calories REAL,
        protein REAL,
        fat REAL,
        carbs REAL,
        createdAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insert demo user and sample scanned food items so UI has data to display
    int demoUserId = await db.insert('users', {
      'username': 'demo',
      'email': 'demo@example.com',
      'password': 'demo123',
      'fullName': 'Demo User',
      'weight': 70.0,
      'height': 175.0,
      'targetCalories': 2000.0,
      'targetProtein': 30.0,
      'targetFat': 25.0,
      'targetCarbs': 45.0,
      'profileImage': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Sample foods
    List<Map<String, dynamic>> samples = [
      {
        'userId': demoUserId,
        'foodName': 'Nasi Goreng',
        'calories': 450.0,
        'protein': 12.0,
        'fat': 18.0,
        'carbs': 60.0,
        'imagePath': null,
        'scannedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'userId': demoUserId,
        'foodName': 'Ayam Bakar',
        'calories': 320.0,
        'protein': 28.0,
        'fat': 10.0,
        'carbs': 5.0,
        'imagePath': null,
        'scannedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'userId': demoUserId,
        'foodName': 'Salad Buah',
        'calories': 150.0,
        'protein': 2.0,
        'fat': 1.0,
        'carbs': 35.0,
        'imagePath': null,
        'scannedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];

    for (var s in samples) {
      await db.insert('food_history', s);
    }

    // Sample favorite foods
    List<Map<String, dynamic>> favorites = [
      {
        'userId': demoUserId,
        'foodName': 'Nasi Goreng',
        'calories': 450.0,
        'protein': 12.0,
        'fat': 18.0,
        'carbs': 60.0,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'userId': demoUserId,
        'foodName': 'Ayam Bakar',
        'calories': 320.0,
        'protein': 28.0,
        'fat': 10.0,
        'carbs': 5.0,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (var f in favorites) {
      await db.insert('favorite_foods', f);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create favorite_foods table if upgrading from v1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          foodName TEXT NOT NULL,
          calories REAL,
          protein REAL,
          fat REAL,
          carbs REAL,
          createdAt TEXT,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add macro target columns to users table when upgrading to v3
      try {
        await db.execute("ALTER TABLE users ADD COLUMN targetProtein REAL DEFAULT 100.0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN targetFat REAL DEFAULT 70.0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN targetCarbs REAL DEFAULT 250.0");
      } catch (_) {}
    }
    if (oldVersion < 4) {
      // Add exercises table when upgrading to v4
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          exerciseName TEXT NOT NULL,
          caloriesBurned REAL NOT NULL,
          durationMinutes INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
    }
  }

  // ==================== USER OPERATIONS ====================
  
  Future<int> registerUser(Map<String, dynamic> user) async {
    Database db = await database;
    user['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> checkUsernameExists(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty;
  }

  Future<bool> checkEmailExists(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty;
  }

  // ==================== FOOD HISTORY OPERATIONS ====================
  
  Future<int> addFoodHistory(Map<String, dynamic> food) async {
    Database db = await database;
    food['scannedAt'] = DateTime.now().toIso8601String();
    return await db.insert('food_history', food);
  }

  Future<List<Map<String, dynamic>>> getFoodHistory(int userId) async {
    Database db = await database;
    return await db.query(
      'food_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scannedAt DESC',
    );
  }

  Future<int> deleteFoodHistory(int id) async {
    Database db = await database;
    return await db.delete(
      'food_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTodayCalories(int userId) async {
    Database db = await database;
    DateTime now = DateTime.now();
    String today = DateTime(now.year, now.month, now.day).toIso8601String();
    
    List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT SUM(calories) as total 
      FROM food_history 
      WHERE userId = ? AND DATE(scannedAt) = DATE(?)
    ''', [userId, today]);
    
    return results.first['total'] ?? 0.0;
  }

  // ==================== FAVORITE FOODS OPERATIONS ====================
  
  Future<int> addFavorite(Map<String, dynamic> favorite) async {
    Database db = await database;
    favorite['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('favorite_foods', favorite);
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    Database db = await database;
    return await db.query(
      'favorite_foods',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteFavorite(int id) async {
    Database db = await database;
    return await db.delete(
      'favorite_foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isFavorite(int userId, String foodName) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'favorite_foods',
      where: 'userId = ? AND foodName = ?',
      whereArgs: [userId, foodName],
    );
    return results.isNotEmpty;
  }

  // ==================== EXERCISE OPERATIONS ====================

  Future<int> addExercise(Map<String, dynamic> exercise) async {
    Database db = await database;
    exercise['date'] = DateTime.now().toIso8601String();
    return await db.insert('exercises', exercise);
  }

  Future<List<Map<String, dynamic>>> getExercises(int userId) async {
    Database db = await database;
    return await db.query(
      'exercises',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<double> getTodayCaloriesBurned(int userId) async {
    Database db = await database;
    DateTime now = DateTime.now();
    String today = DateTime(now.year, now.month, now.day).toIso8601String();

    List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT SUM(caloriesBurned) as total
      FROM exercises
      WHERE userId = ? AND DATE(date) = DATE(?)
    ''', [userId, today]);

    return results.first['total'] ?? 0.0;
  }

  Future<int> deleteExercise(int id) async {
    Database db = await database;
    return await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
