package com.dark.prism

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews

class AqiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {}
    override fun onDisabled(context: Context) {}

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)

            // Get dimensions
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            // Read AQI data
            val aqi = prefs.getInt("aqi_value", 0)
            val description = prefs.getString("aqi_description", "--") ?: "--"
            val pm25 = prefs.getString("aqi_pm25", "0") ?: "0"

            val views = RemoteViews(context.packageName, R.layout.widget_aqi)

            // Background
            views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_glass)

            // Set Data
            views.setTextViewText(R.id.tv_aqi_value, "$aqi")
            views.setTextViewText(R.id.tv_aqi_desc, description.uppercase())
            views.setTextViewText(R.id.tv_aqi_pm25, "PM2.5: $pm25")

            // Colors
            val color = getAqiColor(aqi)
            views.setTextColor(R.id.tv_aqi_desc, color)
            views.setProgressBar(R.id.progress_aqi, 300, aqi, false)

            // RESPONSIVENESS LOGIC
            // Thresholds are approximate dp values.
            // 1x1 is roughly 40-70dp depending on grid. 2x1 is ~150-170dp wide.
            
            // Hide progress bar if too short vertically
            if (minHeight < 80) {
                views.setViewVisibility(R.id.progress_aqi, android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.progress_aqi, android.view.View.VISIBLE)
            }

            // Hide Details (Desc + PM2.5) if too narrow or too short
            if (minWidth < 100 || minHeight < 60) {
                 // Compressed View: Hide Description group
                 views.setViewVisibility(R.id.aqi_details_layout, android.view.View.GONE)
                 // Ensure Value is centered or visible
                 views.setViewVisibility(R.id.tv_aqi_value, android.view.View.VISIBLE)
            } else {
                 views.setViewVisibility(R.id.aqi_details_layout, android.view.View.VISIBLE)
            }

            // Click pending intent
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getAqiColor(aqi: Int): Int {
            return when {
                aqi <= 50 -> Color.parseColor("#00E400")
                aqi <= 100 -> Color.parseColor("#FFFF00")
                aqi <= 150 -> Color.parseColor("#FF7E00")
                aqi <= 200 -> Color.parseColor("#FF0000")
                aqi <= 300 -> Color.parseColor("#8F3F97")
                else -> Color.parseColor("#7E0023")
            }
        }
    }
}
