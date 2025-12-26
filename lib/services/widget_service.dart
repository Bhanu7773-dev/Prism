import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../models/weather_model.dart';
import '../utils/aqi_utils.dart';

/// Service to update home screen widget with weather data
class WidgetService {
  static const String appGroupId = 'group.com.dark.prism';
  static const String androidWidgetName = 'WeatherWidgetProvider';

  /// Update widget with current weather data
  static Future<void> updateWidgetData(
    Weather weather,
    String locationName, {
    ForecastData? forecast,
    bool isCelsius = true,
  }) async {
    try {
      // Helper to convert temperature
      double toTemp(double c) => isCelsius ? c : (c * 9 / 5) + 32;

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
        toTemp(weather.temperature).round().toString(),
      );
      await HomeWidget.saveWidgetData<String>('condition', weather.condition);
      await HomeWidget.saveWidgetData<String>('location', locationName);
      await HomeWidget.saveWidgetData<String>(
        'feelsLike',
        toTemp(weather.feelsLike).round().toString(),
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
        // ... (Existing Daily Forecast Logic - KEEP IT) ...

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
            '${toTemp(maxTemp).round()}°/${toTemp(minTemp).round()}°',
          );
          await HomeWidget.saveWidgetData<String>(
            'day${savedCount}_condition',
            firstItem.condition,
          );
        }

        // Hourly Forecast Data (Next 5 items)
        int hourlyCount = 0;
        for (var item in forecast.list) {
          // Skip if item is before current time (optional, but API usually returns future/current)
          // Just take first 5
          if (hourlyCount >= 5) break;

          await HomeWidget.saveWidgetData<String>(
            'hourly${hourlyCount}_time',
            '${item.dateTime.hour.toString().padLeft(2, '0')}:00',
          );
          await HomeWidget.saveWidgetData<String>(
            'hourly${hourlyCount}_temp',
            '${toTemp(item.temperature).round()}°',
          );
          await HomeWidget.saveWidgetData<String>(
            'hourly${hourlyCount}_condition',
            item.condition,
          );

          hourlyCount++;
        }
      }

      // AQI data
      if (weather.airComponents != null) {
        final pm25 = weather.airComponents!['pm2_5'] ?? 0.0;
        final aqi = AqiUtils.calculateAQI(pm25);
        final description = AqiUtils.getAqiDescription(aqi);
        // We'll save color as a hex string for the Android side to parse, or just save the AQI
        // and let Android logic handle color. Saving mapped values is safer.
        // Let's safe the int value which is safest for platform interaction.

        await HomeWidget.saveWidgetData<int>('aqi_value', aqi);
        await HomeWidget.saveWidgetData<String>('aqi_description', description);
        await HomeWidget.saveWidgetData<String>(
          'aqi_pm25',
          pm25.round().toString(),
        );
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
      await HomeWidget.updateWidget(
        androidName: 'AqiWidgetProvider',
        qualifiedAndroidName: 'com.dark.prism.AqiWidgetProvider',
      );

      // Notification update is now triggered by Native Provider (WeatherWidgetProvider)
      // to avoid MissingPluginException in background isolate.

      // Explicitly trigger notification service for "Instant" update while app is running
      try {
        const channel = MethodChannel('com.dark.prism/widget');
        await channel.invokeMethod('updateNotificationService');
      } catch (e) {
        print('Failed to invoke notification channel: $e');
      }
    } catch (e) {
      print('Widget update failed: $e');
    }
  }

  /// Initialize widget configuration
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }
}
