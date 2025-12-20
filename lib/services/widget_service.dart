import 'package:home_widget/home_widget.dart';
import '../models/weather_model.dart';

/// Service to update home screen widget with weather data
class WidgetService {
  static const String appGroupId = 'group.com.dark.prism';
  static const String androidWidgetName = 'WeatherWidgetProvider';

  /// Update widget with current weather data
  static Future<void> updateWidgetData(
    Weather weather,
    String locationName, {
    ForecastData? forecast,
  }) async {
    try {
      // Calculate day phase based on current time
      final now = weather.localTime;
      final hour = now.hour;
      String dayPhase;

      if (hour >= 6 && hour < 9) {
        dayPhase = 'sunrise';
      } else if (hour >= 9 && hour < 16) {
        dayPhase = 'day';
      } else if (hour >= 16 && hour < 19) {
        dayPhase = 'sunset';
      } else {
        dayPhase = 'night';
      }

      // Save weather data to shared storage
      await HomeWidget.saveWidgetData<String>(
        'temperature',
        weather.temperature.round().toString(),
      );
      await HomeWidget.saveWidgetData<String>('condition', weather.condition);
      await HomeWidget.saveWidgetData<String>('location', locationName);
      await HomeWidget.saveWidgetData<String>(
        'feelsLike',
        weather.feelsLike.round().toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'humidity',
        weather.humidity.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'conditionCode',
        weather.conditionCode.toString(),
      );
      await HomeWidget.saveWidgetData<bool>('isNight', weather.isNight);
      await HomeWidget.saveWidgetData<String>('dayPhase', dayPhase);

      // Sun path data
      await HomeWidget.saveWidgetData<String>(
        'sunrise',
        '${weather.sunrise.hour.toString().padLeft(2, '0')}:${weather.sunrise.minute.toString().padLeft(2, '0')}',
      );
      await HomeWidget.saveWidgetData<String>(
        'sunset',
        '${weather.sunset.hour.toString().padLeft(2, '0')}:${weather.sunset.minute.toString().padLeft(2, '0')}',
      );

      // Wind data
      await HomeWidget.saveWidgetData<String>(
        'windSpeed',
        weather.windSpeed.round().toString(),
      );

      // Details data
      await HomeWidget.saveWidgetData<String>(
        'pressure',
        weather.pressure.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'visibility',
        (weather.visibility / 1000).toStringAsFixed(1),
      );

      // Forecast data for 5 days
      if (forecast != null && forecast.list.isNotEmpty) {
        // Group by day to get daily high/low
        Map<String, List<ForecastItem>> dailyForecasts = {};
        for (var item in forecast.list) {
          String dayKey =
              '${item.dateTime.year}-${item.dateTime.month}-${item.dateTime.day}';
          dailyForecasts.putIfAbsent(dayKey, () => []).add(item);
        }

        List<String> sortedDays = dailyForecasts.keys.toList()..sort();
        // Skip today if necessary, but for simplicity we'll just take the first 5 unique days available
        int savedCount = 0;
        final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

        for (var dayKey in sortedDays) {
          if (savedCount >= 5) break;
          var dayItems = dailyForecasts[dayKey]!;
          var firstItem = dayItems.first;

          double maxTemp = -999;
          double minTemp = 999;
          for (var item in dayItems) {
            if (item.temperature > maxTemp) maxTemp = item.temperature;
            if (item.temperature < minTemp) minTemp = item.temperature;
          }

          savedCount++;
          String dayName = weekdays[firstItem.dateTime.weekday % 7];
          // If it's today, maybe label as 'Now' or just keep day name
          if (dayKey == '${now.year}-${now.month}-${now.day}') {
            dayName = 'Today';
          }

          await HomeWidget.saveWidgetData<String>(
            'day${savedCount}_name',
            dayName,
          );
          await HomeWidget.saveWidgetData<String>(
            'day${savedCount}_temp',
            '${maxTemp.round()}°/${minTemp.round()}°',
          );
          await HomeWidget.saveWidgetData<String>(
            'day${savedCount}_condition',
            firstItem.condition,
          );
        }
      }

      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateTime.now().toIso8601String(),
      );

      // Trigger all widget updates
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        qualifiedAndroidName: 'com.dark.prism.$androidWidgetName',
      );
      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetMediumProvider',
        qualifiedAndroidName: 'com.dark.prism.WeatherWidgetMediumProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'SunPathWidgetProvider',
        qualifiedAndroidName: 'com.dark.prism.SunPathWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'WindWidgetProvider',
        qualifiedAndroidName: 'com.dark.prism.WindWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'DetailsWidgetProvider',
        qualifiedAndroidName: 'com.dark.prism.DetailsWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'ForecastWidgetProvider',
        qualifiedAndroidName: 'com.dark.prism.ForecastWidgetProvider',
      );
    } catch (e) {
      // Widget update failed silently - don't crash the app
    }
  }

  /// Initialize widget configuration
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }
}
