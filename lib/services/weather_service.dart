import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

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
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
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
}
