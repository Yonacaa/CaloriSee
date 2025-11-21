import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  // Menggunakan OpenWeatherMap API (Free)
  // Daftar di: https://openweathermap.org/api
  final String? _apiKey = dotenv.env['OPENWEATHER_API_KEY'];
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>?> getCurrentWeather(String city) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('OpenWeather API key missing, skipping remote call');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/weather?q=$city&appid=${_apiKey!}&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeatherByCoordinates(
      double lat, double lon) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('OpenWeather API key missing, skipping remote call');
        return null;
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/weather?lat=$lat&lon=$lon&appid=${_apiKey!}&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  String getWeatherRecommendation(double temp, String condition) {
    if (temp > 30) {
      return '🔥 Cuaca panas! Minum lebih banyak air dan hindari olahraga berat di luar ruangan.';
    } else if (temp > 25) {
      return '☀️ Cuaca hangat sempurna untuk aktivitas outdoor. Jangan lupa minum air!';
    } else if (temp > 15) {
      return '🌤️ Cuaca nyaman untuk berolahraga. Kebutuhan kalori normal.';
    } else if (temp > 10) {
      return '🌥️ Cuaca sejuk. Tubuh membakar lebih banyak kalori untuk menghangatkan diri.';
    } else {
      return '❄️ Cuaca dingin! Butuh lebih banyak kalori untuk menjaga suhu tubuh.';
    }
  }

  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  double calculateCalorieAdjustment(double temp) {
    // Adjustment factor based on temperature
    if (temp > 30) {
      return 1.1; // 10% more due to heat stress
    } else if (temp < 10) {
      return 1.15; // 15% more due to cold
    }
    return 1.0; // Normal
  }
}

class WeatherModel {
  final String city;
  final double temperature;
  final String condition;
  final String description;
  final double feelsLike;
  final int humidity;

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.feelsLike,
    required this.humidity,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'],
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
    );
  }
}