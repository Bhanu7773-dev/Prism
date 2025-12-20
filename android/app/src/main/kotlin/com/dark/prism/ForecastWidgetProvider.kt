package com.dark.prism

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class ForecastWidgetProvider : AppWidgetProvider() {

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

            val views = RemoteViews(context.packageName, R.layout.widget_forecast)

            // Location
            val location = prefs.getString("location", "Unknown") ?: "Unknown"
            views.setTextViewText(R.id.tv_location, location)

            // Background
            views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_glass)

            // Fill 5 days
            for (i in 1..5) {
                val dayName = prefs.getString("day${i}_name", "---") ?: "---"
                val dayTemp = prefs.getString("day${i}_temp", "--°/--°") ?: "--°/--°"
                val dayCond = prefs.getString("day${i}_condition", "unknown") ?: "unknown"
                
                // Set text
                val nameResId = context.resources.getIdentifier("tv_day${i}_name", "id", context.packageName)
                val tempResId = context.resources.getIdentifier("tv_day${i}_temp", "id", context.packageName)
                val iconResId = context.resources.getIdentifier("iv_day${i}_icon", "id", context.packageName)

                if (nameResId != 0) views.setTextViewText(nameResId, dayName.uppercase())
                if (tempResId != 0) views.setTextViewText(tempResId, dayTemp)
                
                // Set icon
                if (iconResId != 0) {
                    val iconDrawable = getWeatherIcon(dayCond.lowercase())
                    views.setImageViewResource(iconResId, iconDrawable)
                }
            }

            // Click to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getWeatherIcon(condition: String): Int {
            return when {
                condition.contains("rain") || condition.contains("drizzle") || condition.contains("thunder") -> R.drawable.ic_weather_rainy
                condition.contains("snow") -> R.drawable.ic_weather_snowy
                condition.contains("cloud") -> R.drawable.ic_weather_cloudy
                condition.contains("clear") || condition.contains("sunny") -> R.drawable.ic_weather_sunny
                else -> R.drawable.ic_weather_cloudy
            }
        }
    }
}
