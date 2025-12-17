package com.dark.prism

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class WeatherWidgetMediumProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Read weather data
            val temperature = prefs.getString("temperature", "--") ?: "--"
            val condition = prefs.getString("condition", "Unknown") ?: "Unknown"
            val location = prefs.getString("location", "Unknown") ?: "Unknown"
            val feelsLike = prefs.getString("feelsLike", "--") ?: "--"
            val humidity = prefs.getString("humidity", "--") ?: "--"
            val isNight = prefs.getBoolean("isNight", false)

            val views = RemoteViews(context.packageName, R.layout.weather_widget_medium)

            // Glass background
            views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_glass)

            // Set data
            views.setTextViewText(R.id.tv_temperature, "${temperature}°")
            views.setTextViewText(R.id.tv_location, location)
            views.setTextViewText(R.id.tv_condition, condition)
            views.setTextViewText(R.id.tv_feels_like, "Feels ${feelsLike}°")
            views.setTextViewText(R.id.tv_humidity, "${humidity}%")

            // Set weather icon
            val iconRes = getWeatherIcon(condition.lowercase(), isNight)
            views.setImageViewResource(R.id.iv_weather_icon, iconRes)

            // Click to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getWeatherIcon(condition: String, isNight: Boolean): Int {
            if (isNight) return R.drawable.ic_weather_night
            
            return when {
                condition.contains("rain") || condition.contains("drizzle") -> R.drawable.ic_weather_rainy
                condition.contains("snow") -> R.drawable.ic_weather_snowy
                condition.contains("thunder") -> R.drawable.ic_weather_rainy
                condition.contains("cloud") -> R.drawable.ic_weather_cloudy
                condition.contains("clear") || condition.contains("sunny") -> R.drawable.ic_weather_sunny
                else -> R.drawable.ic_weather_cloudy
            }
        }
    }
}
