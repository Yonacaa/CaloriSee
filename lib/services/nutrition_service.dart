import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutritionService {
  // Edamam Nutrition Analysis API (Free tier: 100 requests/month)
  // Sign up: https://developer.edamam.com/
  final String? _appId = dotenv.env['EDAMAM_APP_ID'];
  final String? _appKey = dotenv.env['EDAMAM_APP_KEY'];
  static const String _baseUrl = 'https://api.edamam.com/api/nutrition-details';

  // Alternative: CalorieNinjas API
  final String? _ninjaApiKey = dotenv.env['CALORIE_NINJAS_API_KEY'] ?? dotenv.env['NINJA_API_KEY'];
  static const String _ninjaBaseUrl = 'https://api.calorieninjas.com/v1/nutrition';

  /// Get nutrition from food name using Edamam
  Future<Map<String, dynamic>?> getNutritionFromText(String foodText) async {
    try {
      // Prefer Edamam when credentials are present
      if (_appId != null && _appId!.isNotEmpty && _appKey != null && _appKey!.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$_baseUrl?app_id=${_appId!}&app_key=${_appKey!}'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'title': 'My Food',
            'ingr': [foodText]
          }),
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          debugPrint('Edamam Error: ${response.statusCode}');
          return null;
        }
      }

      // Fallback to CalorieNinjas if available
      if (_ninjaApiKey != null && _ninjaApiKey!.isNotEmpty) {
        final ninja = await getNutritionFromCalorieNinjas(foodText);
        if (ninja != null && ninja.isNotEmpty) {
          // Return first match in a simple wrapper
          return {
            'name': foodText,
            'items': ninja,
          };
        }
        return null;
      }

      // Last resort: return mock nutrition data
      return getMockNutrition(foodText);
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
      return null;
    }
  }

  /// Get nutrition using CalorieNinjas API (simpler alternative)
  Future<List<Map<String, dynamic>>?> getNutritionFromCalorieNinjas(
      String query) async {
    try {
      if (_ninjaApiKey == null || _ninjaApiKey!.isEmpty) {
        debugPrint('CalorieNinjas API key missing, skipping remote call');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_ninjaBaseUrl?query=$query'),
        headers: {
          'X-Api-Key': _ninjaApiKey!,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        debugPrint('CalorieNinjas Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
      return null;
    }
  }

  /// Parse nutrition data from Edamam response
  Map<String, double> parseEdamamNutrition(Map<String, dynamic> data) {
    try {
      final nutrients = data['totalNutrients'] ?? {};
      
      return {
        'calories': (data['calories'] ?? 0).toDouble(),
        'protein': (nutrients['PROCNT']?['quantity'] ?? 0).toDouble(),
        'fat': (nutrients['FAT']?['quantity'] ?? 0).toDouble(),
        'carbs': (nutrients['CHOCDF']?['quantity'] ?? 0).toDouble(),
        'fiber': (nutrients['FIBTG']?['quantity'] ?? 0).toDouble(),
        'sugar': (nutrients['SUGAR']?['quantity'] ?? 0).toDouble(),
        'sodium': (nutrients['NA']?['quantity'] ?? 0).toDouble(),
      };
    } catch (e) {
      debugPrint('Error parsing nutrition: $e');
      return {};
    }
  }

  /// Parse nutrition data from CalorieNinjas response
  Map<String, double> parseNinjaNutrition(Map<String, dynamic> item) {
    return {
      'calories': (item['calories'] ?? 0).toDouble(),
      'protein': (item['protein_g'] ?? 0).toDouble(),
      'fat': (item['fat_total_g'] ?? 0).toDouble(),
      'carbs': (item['carbohydrates_total_g'] ?? 0).toDouble(),
      'fiber': (item['fiber_g'] ?? 0).toDouble(),
      'sugar': (item['sugar_g'] ?? 0).toDouble(),
      'sodium': (item['sodium_mg'] ?? 0).toDouble(),
    };
  }

  /// Get mock nutrition data (for demo/offline mode)
  Map<String, dynamic> getMockNutrition(String foodName) {
    // Database makanan Indonesia populer
    final Map<String, Map<String, double>> foodDatabase = {
      'nasi goreng': {
        'calories': 450,
        'protein': 12,
        'fat': 18,
        'carbs': 60,
        'fiber': 3,
        'sugar': 5,
      },
      'nasi putih': {
        'calories': 350,
        'protein': 7,
        'fat': 1,
        'carbs': 78,
        'fiber': 1,
        'sugar': 0,
      },
      'ayam goreng': {
        'calories': 320,
        'protein': 28,
        'fat': 22,
        'carbs': 8,
        'fiber': 0,
        'sugar': 2,
      },
      'gado-gado': {
        'calories': 280,
        'protein': 10,
        'fat': 15,
        'carbs': 35,
        'fiber': 8,
        'sugar': 8,
      },
      'sate ayam': {
        'calories': 220,
        'protein': 25,
        'fat': 12,
        'carbs': 10,
        'fiber': 2,
        'sugar': 6,
      },
      'mie goreng': {
        'calories': 380,
        'protein': 14,
        'fat': 16,
        'carbs': 52,
        'fiber': 3,
        'sugar': 4,
      },
      'rendang': {
        'calories': 410,
        'protein': 22,
        'fat': 32,
        'carbs': 8,
        'fiber': 2,
        'sugar': 3,
      },
      'bakso': {
        'calories': 290,
        'protein': 18,
        'fat': 10,
        'carbs': 35,
        'fiber': 2,
        'sugar': 3,
      },
      'soto ayam': {
        'calories': 240,
        'protein': 20,
        'fat': 8,
        'carbs': 25,
        'fiber': 3,
        'sugar': 4,
      },
      'nasi uduk': {
        'calories': 330,
        'protein': 8,
        'fat': 12,
        'carbs': 50,
        'fiber': 2,
        'sugar': 2,
      },
      'tempe goreng': {
        'calories': 190,
        'protein': 15,
        'fat': 10,
        'carbs': 12,
        'fiber': 5,
        'sugar': 1,
      },
      'tahu goreng': {
        'calories': 150,
        'protein': 12,
        'fat': 8,
        'carbs': 10,
        'fiber': 3,
        'sugar': 1,
      },
      'pecel lele': {
        'calories': 260,
        'protein': 22,
        'fat': 16,
        'carbs': 8,
        'fiber': 2,
        'sugar': 2,
      },
      'nasi padang': {
        'calories': 520,
        'protein': 20,
        'fat': 28,
        'carbs': 55,
        'fiber': 4,
        'sugar': 5,
      },
      'pizza': {
        'calories': 480,
        'protein': 18,
        'fat': 22,
        'carbs': 58,
        'fiber': 3,
        'sugar': 6,
      },
      'burger': {
        'calories': 540,
        'protein': 25,
        'fat': 28,
        'carbs': 48,
        'fiber': 3,
        'sugar': 8,
      },
      'kentang goreng': {
        'calories': 320,
        'protein': 4,
        'fat': 15,
        'carbs': 42,
        'fiber': 4,
        'sugar': 1,
      },
      'salad': {
        'calories': 120,
        'protein': 5,
        'fat': 8,
        'carbs': 10,
        'fiber': 4,
        'sugar': 5,
      },
    };

    String searchKey = foodName.toLowerCase();
    
    // Try to find exact match
    if (foodDatabase.containsKey(searchKey)) {
      return {
        'name': foodName,
        'nutrition': foodDatabase[searchKey]!,
      };
    }

    // Try partial match
    for (var entry in foodDatabase.entries) {
      if (searchKey.contains(entry.key) || entry.key.contains(searchKey)) {
        return {
          'name': entry.key,
          'nutrition': entry.value,
        };
      }
    }

    // Default/unknown food
    return {
      'name': foodName,
      'nutrition': {
        'calories': 250.0,
        'protein': 10.0,
        'fat': 8.0,
        'carbs': 35.0,
        'fiber': 2.0,
        'sugar': 3.0,
      },
    };
  }
}