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

  /// Search for city suggestions with fuzzy matching (Photon OSM) and OpenWeatherMap fallback
  /// Search for city suggestions with fuzzy matching in English and place relevance ranking
  Future<List<CityResult>> searchCities(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Primary: Photon (Komoot / OpenStreetMap) with English forced & place ranking
    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final response = await http
          .get(
            Uri.parse(
              'https://photon.komoot.io/api/?q=$encoded&limit=10&osm_tag=place&lang=en',
            ),
            headers: {
              'User-Agent': 'PrismWeatherApp/1.0 (com.dark.prism)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        final scoredFeatures = <Map<String, dynamic>>[];
        for (final f in features) {
          if (f is Map<String, dynamic>) scoredFeatures.add(f);
        }

        // Sort by place importance: Country > City > Town > State > Village > Hamlet
        scoredFeatures.sort((a, b) {
          final propsA = (a['properties'] as Map<String, dynamic>?) ?? {};
          final propsB = (b['properties'] as Map<String, dynamic>?) ?? {};
          return _placeScore(propsB).compareTo(_placeScore(propsA));
        });

        final results = <CityResult>[];
        final seen = <String>{};

        for (final f in scoredFeatures) {
          final city = CityResult.fromPhoton(f);
          if (city.name.isEmpty) continue;

          final props = (f['properties'] as Map<String, dynamic>?) ?? {};
          final score = _placeScore(props);

          // If we already have major matches, discard tiny hamlets & obscure neighbourhoods
          if (results.isNotEmpty && score <= 15) {
            continue;
          }

          final key =
              '${city.name.toLowerCase()}_${city.state?.toLowerCase()}_${city.country.toLowerCase()}';
          if (!seen.contains(key)) {
            seen.add(key);
            results.add(city);
          }
          if (results.length >= 6) break;
        }
        if (results.isNotEmpty) return results;
      }
    } catch (_) {
      // Fall through to Open-Meteo / OpenWeatherMap
    }

    // 2. Secondary: Open-Meteo Geocoding (English, ranked by population)
    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final response = await http
          .get(
            Uri.parse(
              'https://geocoding-api.open-meteo.com/v1/search?name=$encoded&count=5&language=en&format=json',
            ),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['results'] ?? [];
        if (list.isNotEmpty) {
          return list.map((item) {
            final map = item as Map<String, dynamic>;
            return CityResult(
              name: (map['name'] ?? '').toString(),
              state: map['admin1']?.toString(),
              country: (map['country'] ?? '').toString(),
              lat: (map['latitude'] as num).toDouble(),
              lon: (map['longitude'] as num).toDouble(),
              placeType: 'city',
            );
          }).toList();
        }
      }
    } catch (_) {}

    // 3. Fallback: OpenWeatherMap Geo API
    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final response = await http
          .get(
            Uri.parse(
              'https://api.openweathermap.org/geo/1.0/direct?q=$encoded&limit=5&appid=$_apiKey',
            ),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CityResult.fromJson(json)).toList();
      }
    } catch (_) {}

    return [];
  }

  static int _placeScore(Map<String, dynamic> props) {
    final osmVal =
        (props['osm_value'] ?? props['type'] ?? '').toString().toLowerCase();
    switch (osmVal) {
      case 'country':
        return 100;
      case 'city':
        return 90;
      case 'town':
        return 80;
      case 'state':
      case 'province':
      case 'administrative':
        return 70;
      case 'municipality':
      case 'village':
        return 40;
      case 'suburb':
      case 'district':
        return 30;
      case 'hamlet':
        return 10;
      case 'neighbourhood':
      case 'locality':
      case 'isolated_dwelling':
        return 5;
      default:
        return 20;
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
  final String? placeType;

  CityResult({
    required this.name,
    this.state,
    required this.country,
    required this.lat,
    required this.lon,
    this.placeType,
  });

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name'] ?? '',
      state: json['state'],
      country: json['country'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      placeType: 'city',
    );
  }

  factory CityResult.fromPhoton(Map<String, dynamic> feature) {
    final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
    final geometry = (feature['geometry'] as Map<String, dynamic>?) ?? {};
    final coords = (geometry['coordinates'] as List<dynamic>?) ?? [];

    final lon = (coords.isNotEmpty ? coords[0] as num : 0.0).toDouble();
    final lat = (coords.length > 1 ? coords[1] as num : 0.0).toDouble();

    final name = (props['name'] ?? props['city'] ?? '').toString();
    final state = props['state']?.toString();
    final country = (props['country'] ?? props['countrycode'] ?? '').toString();
    final placeType = (props['osm_value'] ?? props['type'] ?? '').toString();

    return CityResult(
      name: name,
      state: state,
      country: country,
      lat: lat,
      lon: lon,
      placeType: placeType,
    );
  }

  String get subtitle {
    final parts = <String>[];
    if (state != null &&
        state!.isNotEmpty &&
        state!.toLowerCase() != country.toLowerCase()) {
      parts.add(state!);
    }
    if (country.isNotEmpty && country.toLowerCase() != name.toLowerCase()) {
      parts.add(country);
    }
    if (parts.isEmpty) {
      if (placeType == 'country') return 'Country';
      if (placeType == 'state') return 'State';
      if (country.isNotEmpty) return country;
    }
    return parts.join(', ');
  }

  String get displayName {
    final sub = subtitle;
    if (sub.isNotEmpty && sub != 'Country') {
      return '$name, $sub';
    }
    return name;
  }
}
