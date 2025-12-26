import 'package:workmanager/workmanager.dart';
import 'package:home_widget/home_widget.dart';

const String updateWeatherTask = "updateWeatherTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case updateWeatherTask:
        print("Background Fetch: Starting weather update");
        try {
          // Trigger native service update
          print("Background Task Executed. Triggering Service Update.");
          await HomeWidget.updateWidget(
            androidName: 'WeatherWidgetProvider',
            qualifiedAndroidName: 'com.dark.prism.WeatherWidgetProvider',
          );
        } catch (e) {
          print("Background Task Error: $e");
        }
        break;
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // For testing, remove in prod
    );

    // Register periodic task (every 15 mins)
    await Workmanager().registerPeriodicTask(
      "1",
      updateWeatherTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
