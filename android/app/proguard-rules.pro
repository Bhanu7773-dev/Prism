# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep our Widget Providers and Service because they are referenced by String from Dart (HomeWidget)
-keep class com.dark.prism.WeatherWidgetProvider { *; }
-keep class com.dark.prism.WeatherWidgetMediumProvider { *; }
-keep class com.dark.prism.SunPathWidgetProvider { *; }
-keep class com.dark.prism.WindWidgetProvider { *; }
-keep class com.dark.prism.DetailsWidgetProvider { *; }
-keep class com.dark.prism.ForecastWidgetProvider { *; }
-keep class com.dark.prism.AqiWidgetProvider { *; }
-keep class com.dark.prism.WeatherNotificationService { *; }

# Keep R generated class to ensure resource lookup works if reflection is used (optional but safe)
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable

# Ignore missing Play Core classes referenced by Flutter Engine (Deferred Components)
-dontwarn com.google.android.play.core.**
