class Weather {
  final String cityName;
  final double temperature;
  final String condition;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final int pressure;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        (json['sys']['sunrise'] ?? 0) * 1000,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        (json['sys']['sunset'] ?? 0) * 1000,
      ),
    );
  }
}

class ForecastItem {
  final DateTime dateTime;
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

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
    );
  }
}

class ForecastData {
  final List<ForecastItem> list;

  ForecastData({required this.list});

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    var list = json['list'] as List;
    List<ForecastItem> forecastList = list
        .map((i) => ForecastItem.fromJson(i))
        .toList();
    return ForecastData(list: forecastList);
  }
}
