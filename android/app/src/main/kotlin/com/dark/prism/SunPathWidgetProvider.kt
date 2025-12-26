package com.dark.prism

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class SunPathWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

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

            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)

            val sunrise = prefs.getString("sunrise", "06:00") ?: "06:00"
            val sunset = prefs.getString("sunset", "18:00") ?: "18:00"

            val views = RemoteViews(context.packageName, R.layout.widget_sun_path)

            views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_glass)
            views.setTextViewText(R.id.tv_sunrise, sunrise)
            views.setTextViewText(R.id.tv_sunset, sunset)

            // RESPONSIVENESS
            if (minWidth < 110) {
                // Hide center icon if tight
                 views.setViewVisibility(R.id.icon_sun, android.view.View.GONE)
            } else {
                 views.setViewVisibility(R.id.icon_sun, android.view.View.VISIBLE)
            }

            if (minWidth < 70) {
                // If super tight, hide Sunrise, keep Sunset (usually next event interest)
                // In a perfect world we'd check time and show next event.
                views.setViewVisibility(R.id.layout_sunrise, android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.layout_sunrise, android.view.View.VISIBLE)
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
    }
}
