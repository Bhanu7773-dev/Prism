import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

// Structured Grid for Fast O(1) Lookup
class WindGrid {
  final List<WindPoint> points;
  final int width;
  final int height;
  final double latMin; // Bottom Latitude
  final double lonMin; // Left Longitude
  final double latStep;
  final double lonStep;

  WindGrid({
    required this.points,
    required this.width,
    required this.height,
    required this.latMin,
    required this.lonMin,
    required this.latStep,
    required this.lonStep,
  });

  bool get isEmpty => points.isEmpty;
}

class WindDataService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WindGrid> fetchWindGrid(
    double centerLat,
    double centerLon,
    double spanDegrees,
  ) async {
    final lats = <double>[];
    final lons = <double>[];

    // 10x10 Grid (100 points) - Safe API limit
    final gridSize = 10;
    final totalCoverage = spanDegrees * 1.5;
    final step = totalCoverage / (gridSize - 1);
    final startOffset = -totalCoverage / 2;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        double latOffset = startOffset + (i * step);
        double lonOffset = startOffset + (j * step);

        double lat = (centerLat + latOffset).clamp(-90.0, 90.0);
        double lon = (centerLon + lonOffset);

        if (lon > 180) lon -= 360;
        if (lon < -180) lon += 360;

        lats.add(lat);
        lons.add(lon);
      }
    }

    // Min/Max for Grid Object
    // Note: lats generated from -Offset to +Offset.
    // lats[0] is Bottom (Lowest Lat) if offset is negative?
    // Actually: centerLat + (-val) = Lower Latitude (South).
    // So Loop i=0 is South, i=5 is North.
    double latMin = centerLat + startOffset;
    double lonMin = centerLon + startOffset;
    // Handle wrap manually for structure if needed, but for local grid logic we assume local linearity

    final latStr = lats.map((l) => l.toStringAsFixed(2)).join(',');
    final lonStr = lons.map((l) => l.toStringAsFixed(2)).join(',');

    final url = Uri.parse(
      '$_baseUrl?latitude=$latStr&longitude=$lonStr&current=wind_speed_10m,wind_direction_10m&wind_speed_unit=ms',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> results;
        if (data is List) {
          results = data;
        } else {
          results = [data];
        }

        final points = <WindPoint>[];
        for (int i = 0; i < results.length; i++) {
          final current = results[i]['current'];
          final speed = (current['wind_speed_10m'] as num).toDouble();
          final dir = (current['wind_direction_10m'] as num).toDouble();

          points.add(
            WindPoint(
              lat: lats[i],
              lon: lons[i],
              speed: speed,
              direction: dir,
              u: _calculateU(speed, dir),
              v: _calculateV(speed, dir),
            ),
          );
        }

        return WindGrid(
          points: points,
          width: gridSize,
          height: gridSize,
          latMin: latMin,
          lonMin: lonMin,
          latStep: step,
          lonStep: step,
        );
      } else {
        throw Exception('Failed to load wind data');
      }
    } catch (e) {
      throw Exception('Error fetching wind data: $e');
    }
  }

  // Fetches context (Sunrise, Sunset, Weather Code) for theming
  Future<WeatherContext> fetchWeatherContext(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&daily=sunrise,sunset&current=weather_code&timezone=auto',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        final current = data['current'];

        return WeatherContext(
          sunrise: DateTime.parse(daily['sunrise'][0]),
          sunset: DateTime.parse(daily['sunset'][0]),
          weatherCode: current['weather_code'] as int,
        );
      }
      throw Exception('Failed to load context');
    } catch (e) {
      final now = DateTime.now();
      return WeatherContext(
        sunrise: DateTime(now.year, now.month, now.day, 6),
        sunset: DateTime(now.year, now.month, now.day, 18),
        weatherCode: 0,
      );
    }
  }

  double _calculateU(double speed, double dirDeg) {
    // Meteo direction: 0=North (Blows South), 90=East (Blows West)
    // U is West-to-East.
    // Wind Direction is "Coming FROM".
    // 0 deg (North Wind) comes FROM North, blows TO South.
    // U should be 0, V should be negative (South).
    // sin(0)=0. cos(0)=1. -speed*1 = -speed. Correct.

    // 90 deg (East Wind) comes FROM East, blows TO West.
    // U should be negative (West).
    // sin(90)=1. -speed*1 = -speed. Correct.
    final rad = dirDeg * (pi / 180.0);
    return -speed * sin(rad);
  }

  double _calculateV(double speed, double dirDeg) {
    final rad = dirDeg * (pi / 180.0);
    return -speed * cos(rad);
  }
}

class WindPoint {
  final double lat;
  final double lon;
  final double speed;
  final double direction;
  final double u;
  final double v;

  WindPoint({
    required this.lat,
    required this.lon,
    required this.speed,
    required this.direction,
    required this.u,
    required this.v,
  });
}

class WeatherContext {
  final DateTime sunrise;
  final DateTime sunset;
  final int weatherCode;

  WeatherContext({
    required this.sunrise,
    required this.sunset,
    required this.weatherCode,
  });
}
