class Weather {
  final String cityName;
  final double temperature;
  final String condition;
  final int conditionCode; // OpenWeatherMap condition code
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final int pressure;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final int timezoneOffset; // Timezone offset in seconds from UTC
  final double latitude;
  final double longitude;
  final int? aqi;
  final Map<String, double>? airComponents;
  final double? uvIndex;
  final double? rainProb; // Probability of precipitation (0-1)
  final String? moonPhase; // Description e.g., "Full Moon"
  final List<String>? alerts;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.conditionCode,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    required this.timezoneOffset,
    required this.latitude,
    required this.longitude,
    this.aqi,
    this.airComponents,
    this.uvIndex,
    this.rainProb,
    this.moonPhase,
    this.alerts,
  });

  /// Get current time in the city's timezone
  /// Returns a non-UTC DateTime so .hour and .minute are the city's local values
  DateTime get localTime {
    final utcNow = DateTime.now().toUtc();
    final shifted = utcNow.add(Duration(seconds: timezoneOffset));
    // Create non-UTC DateTime so .hour/.minute return actual local values
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  Weather copyWith({
    int? aqi,
    Map<String, double>? airComponents,
    double? uvIndex,
    double? rainProb,
    String? moonPhase,
    List<String>? alerts,
  }) {
    return Weather(
      cityName: cityName,
      temperature: temperature,
      condition: condition,
      conditionCode: conditionCode,
      description: description,
      iconCode: iconCode,
      humidity: humidity,
      windSpeed: windSpeed,
      feelsLike: feelsLike,
      pressure: pressure,
      visibility: visibility,
      sunrise: sunrise,
      sunset: sunset,
      timezoneOffset: timezoneOffset,
      latitude: latitude,
      longitude: longitude,
      aqi: aqi ?? this.aqi,
      airComponents: airComponents ?? this.airComponents,
      uvIndex: uvIndex ?? this.uvIndex,
      rainProb: rainProb ?? this.rainProb,
      moonPhase: moonPhase ?? this.moonPhase,
      alerts: alerts ?? this.alerts,
    );
  }

  /// Check if it's currently night time in the city
  bool get isNight {
    final now = localTime;
    // sunrise and sunset are already non-UTC DateTimes with correct local hour/minute
    final nowMinutes = now.hour * 60 + now.minute;
    final sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
    final sunsetMinutes = sunset.hour * 60 + sunset.minute;

    return nowMinutes < sunriseMinutes || nowMinutes > sunsetMinutes;
  }

  /// Convert a UTC DateTime to the city's local time
  /// Returns a non-UTC DateTime so .hour and .minute are the city's local values
  DateTime toLocalTime(DateTime utcTime) {
    final shifted = utcTime.toUtc().add(Duration(seconds: timezoneOffset));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  factory Weather.fromJson(Map<String, dynamic> json) {
    final timezoneOffset = json['timezone'] ?? 0;

    // Convert sunrise/sunset from UTC timestamp to city's local time
    // We get the UTC timestamp and add offset, then create a non-UTC DateTime
    // to ensure .hour and .minute return the city's local time values
    final sunriseUtc = DateTime.fromMillisecondsSinceEpoch(
      (json['sys']['sunrise'] ?? 0) * 1000,
      isUtc: true,
    );
    final sunsetUtc = DateTime.fromMillisecondsSinceEpoch(
      (json['sys']['sunset'] ?? 0) * 1000,
      isUtc: true,
    );

    // Add timezone offset and create LOCAL DateTime objects
    // This is critical: DateTime.add() keeps UTC mode, so we need to extract
    // the shifted values and create new non-UTC DateTimes
    final sunriseShifted = sunriseUtc.add(Duration(seconds: timezoneOffset));
    final sunsetShifted = sunsetUtc.add(Duration(seconds: timezoneOffset));

    // Create non-UTC DateTimes so .hour and .minute return the actual local values
    final sunriseLocal = DateTime(
      sunriseShifted.year,
      sunriseShifted.month,
      sunriseShifted.day,
      sunriseShifted.hour,
      sunriseShifted.minute,
      sunriseShifted.second,
      sunriseShifted.millisecond,
    );
    final sunsetLocal = DateTime(
      sunsetShifted.year,
      sunsetShifted.month,
      sunsetShifted.day,
      sunsetShifted.hour,
      sunsetShifted.minute,
      sunsetShifted.second,
      sunsetShifted.millisecond,
    );

    return Weather(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      conditionCode: json['weather'][0]['id'] ?? 800,
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      timezoneOffset: timezoneOffset,
      sunrise: sunriseLocal,
      sunset: sunsetLocal,
      latitude: (json['coord']?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['coord']?['lon'] as num?)?.toDouble() ?? 0.0,
      aqi: json['aqi'] as int?,
      airComponents: (json['airComponents'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      uvIndex: (json['uvi'] as num?)?.toDouble(),
      rainProb: (json['pop'] as num?)?.toDouble(),
      // Alerts and Moon Phase usually come from OneCall, so we might inject them later
    );
  }
}

class ForecastItem {
  final DateTime dateTime; // Already in city's local time
  final double temperature;
  final String condition;
  final String iconCode;
  final int humidity;

  ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.condition,
    required this.iconCode,
    required this.humidity,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json, int timezoneOffset) {
    // Convert UTC to city's local time and create non-UTC DateTime
    final utcTime = DateTime.fromMillisecondsSinceEpoch(
      json['dt'] * 1000,
      isUtc: true,
    );
    final shifted = utcTime.add(Duration(seconds: timezoneOffset));
    final localDateTime = DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );

    return ForecastItem(
      dateTime: localDateTime,
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
    );
  }
}

class ForecastData {
  final List<ForecastItem> list;
  final int timezoneOffset;

  ForecastData({required this.list, required this.timezoneOffset});

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    // Get timezone offset from the city info
    final timezoneOffset = json['city']?['timezone'] ?? 0;

    var list = json['list'] as List;
    List<ForecastItem> forecastList = list
        .map((i) => ForecastItem.fromJson(i, timezoneOffset))
        .toList();
    return ForecastData(list: forecastList, timezoneOffset: timezoneOffset);
  }
}
