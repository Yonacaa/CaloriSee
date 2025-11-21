import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExerciseService {
  // API-Ninjas Exercise API
  final String? _apiKey = dotenv.env['API_NINJAS_KEY'] ?? dotenv.env['API_NINJAS'] ?? dotenv.env['NINJA_API_KEY'];
  static const String _baseUrl = 'https://api.api-ninjas.com/v1/exercises';

  /// Get exercises by muscle group
  Future<List<Map<String, dynamic>>?> getExercisesByMuscle(String muscle) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('API-Ninjas key missing, returning mock exercises');
        return getMockExercises();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl?muscle=$muscle'),
        headers: {
          'X-Api-Key': _apiKey!,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      return null;
    }
  }

  /// Get exercises by type
  Future<List<Map<String, dynamic>>?> getExercisesByType(String type) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('API-Ninjas key missing, returning mock exercises');
        return getMockExercises();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl?type=$type'),
        headers: {
          'X-Api-Key': _apiKey!,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      return null;
    }
  }

  /// Calculate calories burned
  /// Formula: MET × weight(kg) × duration(hours)
  double calculateCaloriesBurned({
    required double met,
    required double weightKg,
    required int durationMinutes,
  }) {
    double hours = durationMinutes / 60;
    return met * weightKg * hours;
  }

  /// Get mock exercise data
  List<Map<String, dynamic>> getMockExercises() {
    return [
      {
        'name': 'Push-ups',
        'type': 'strength',
        'muscle': 'chest',
        'difficulty': 'beginner',
        'instructions': 'Start in a plank position. Lower your body until chest nearly touches floor. Push back up.',
        'met': 3.8,
        'icon': '💪',
      },
      {
        'name': 'Squats',
        'type': 'strength',
        'muscle': 'quadriceps',
        'difficulty': 'beginner',
        'instructions': 'Stand with feet shoulder-width apart. Bend knees and lower hips. Return to start.',
        'met': 5.0,
        'icon': '🦵',
      },
      {
        'name': 'Plank',
        'type': 'strength',
        'muscle': 'abdominals',
        'difficulty': 'beginner',
        'instructions': 'Hold a push-up position with forearms on ground. Keep body straight.',
        'met': 4.0,
        'icon': '🧘',
      },
      {
        'name': 'Running',
        'type': 'cardio',
        'muscle': 'cardio',
        'difficulty': 'intermediate',
        'instructions': 'Maintain steady pace. Land on midfoot. Keep posture upright.',
        'met': 8.0,
        'icon': '🏃',
      },
      {
        'name': 'Jumping Jacks',
        'type': 'cardio',
        'muscle': 'full_body',
        'difficulty': 'beginner',
        'instructions': 'Jump while spreading legs and raising arms overhead. Return to start.',
        'met': 7.5,
        'icon': '🤸',
      },
      {
        'name': 'Cycling',
        'type': 'cardio',
        'muscle': 'quadriceps',
        'difficulty': 'beginner',
        'instructions': 'Pedal at moderate to vigorous pace. Adjust resistance as needed.',
        'met': 6.8,
        'icon': '🚴',
      },
      {
        'name': 'Pull-ups',
        'type': 'strength',
        'muscle': 'lats',
        'difficulty': 'advanced',
        'instructions': 'Hang from bar. Pull body up until chin clears bar. Lower with control.',
        'met': 4.5,
        'icon': '💪',
      },
      {
        'name': 'Burpees',
        'type': 'cardio',
        'muscle': 'full_body',
        'difficulty': 'advanced',
        'instructions': 'Drop to push-up. Jump feet forward. Jump up with arms overhead.',
        'met': 8.0,
        'icon': '🔥',
      },
      {
        'name': 'Lunges',
        'type': 'strength',
        'muscle': 'glutes',
        'difficulty': 'beginner',
        'instructions': 'Step forward and lower hips. Push back to start. Alternate legs.',
        'met': 4.0,
        'icon': '🦵',
      },
      {
        'name': 'Mountain Climbers',
        'type': 'cardio',
        'muscle': 'abdominals',
        'difficulty': 'intermediate',
        'instructions': 'Start in plank. Alternate bringing knees to chest quickly.',
        'met': 8.0,
        'icon': '⛰️',
      },
    ];
  }

  /// Get workout plan by goal
  Map<String, dynamic> getWorkoutPlan(String goal) {
    final Map<String, Map<String, dynamic>> plans = {
      'weight_loss': {
        'name': 'Weight Loss Program',
        'description': 'High-intensity cardio with moderate strength training',
        'duration_weeks': 8,
        'days_per_week': 5,
        'exercises': [
          'Running',
          'Burpees',
          'Jumping Jacks',
          'Mountain Climbers',
          'Cycling',
        ],
        'calories_target': -500, // Deficit
      },
      'muscle_gain': {
        'name': 'Muscle Building Program',
        'description': 'Progressive strength training with adequate rest',
        'duration_weeks': 12,
        'days_per_week': 4,
        'exercises': [
          'Push-ups',
          'Pull-ups',
          'Squats',
          'Lunges',
          'Plank',
        ],
        'calories_target': 300, // Surplus
      },
      'maintenance': {
        'name': 'Fitness Maintenance',
        'description': 'Balanced cardio and strength training',
        'duration_weeks': 4,
        'days_per_week': 3,
        'exercises': [
          'Squats',
          'Push-ups',
          'Plank',
          'Cycling',
          'Lunges',
        ],
        'calories_target': 0, // Maintenance
      },
    };

    return plans[goal] ?? plans['maintenance']!;
  }
}