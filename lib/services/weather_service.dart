import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/moon_utils.dart';
import '../api_keys.dart';

class WeatherService {
  static const String _apiKey = ApiKeys.openWeatherMap;
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?q=$cityName&appid=$_apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final weather = Weather.fromJson(jsonDecode(response.body));
      final pollution = await _getPollutionData(
        weather.latitude,
        weather.longitude,
      );
      final uv = await _getUvIndex(weather.latitude, weather.longitude);

      return weather.copyWith(
        aqi: pollution?['main']?['aqi'],
        airComponents: (pollution?['components'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        uvIndex: uv,
        moonPhase: MoonUtils.getMoonPhaseName(
          MoonUtils.getMoonPhase(weather.localTime),
        ),
      );
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final weather = Weather.fromJson(jsonDecode(response.body));
      final pollution = await _getPollutionData(
        weather.latitude,
        weather.longitude,
      );
      final uv = await _getUvIndex(weather.latitude, weather.longitude);

      return weather.copyWith(
        aqi: pollution?['main']?['aqi'],
        airComponents: (pollution?['components'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        uvIndex: uv,
        moonPhase: MoonUtils.getMoonPhaseName(
          MoonUtils.getMoonPhase(weather.localTime),
        ),
      );
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>?> _getPollutionData(
    double lat,
    double lon,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Returns the first item which has "main" and "components"
        if (data['list'] != null && data['list'].isNotEmpty) {
          return data['list'][0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Failed to load Pollution Data: $e');
    }
    return null;
  }

  Future<double?> _getUvIndex(double lat, double lon) async {
    try {
      // Try One Call API (standard for UV)
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,daily,alerts&appid=$_apiKey&units=metric',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['current']['uvi'] as num).toDouble();
      }
    } catch (e) {
      // Ignore, return null
    }
    return null;
  }

  Future<ForecastData> getForecast(double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      ),
    );

    if (response.statusCode == 200) {
      return ForecastData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  /// Search for city suggestions using OpenWeatherMap Geo API
  Future<List<CityResult>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CityResult.fromJson(json)).toList();
    } else {
      return [];
    }
  }
}

/// Model for city search results
class CityResult {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  CityResult({
    required this.name,
    this.state,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name'] ?? '',
      state: json['state'],
      country: json['country'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  String get displayName {
    if (state != null && state!.isNotEmpty) {
      return '$name, $state, $country';
    }
    return '$name, $country';
  }
}
