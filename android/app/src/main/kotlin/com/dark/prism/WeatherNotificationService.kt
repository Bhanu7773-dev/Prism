package com.dark.prism

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class WeatherNotificationService : Service() {

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        updateNotification()
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Weather Persistent Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun updateNotification() {
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Read Data
        val temperature = prefs.getString("temperature", "--") ?: "--"
        val condition = prefs.getString("condition", "Unknown") ?: "Unknown"
        val location = prefs.getString("location", "Location") ?: "Location"
        val highLow = prefs.getString("day1_temp", "--/--") ?: "--/--"
        val isNight = prefs.getBoolean("isNight", false)
        
        // Define Icon and Time variables BEFORE using them
        val iconRes = getWeatherIcon(condition.lowercase(), isNight)
        val time = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date())

        // Intent to open app
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Custom Layout (Collapsed)
        val notificationLayout = RemoteViews(packageName, R.layout.notification_weather)
        bindViewData(notificationLayout, temperature, location, condition, highLow, time, iconRes)

        // Custom Layout (Expanded)
        val expandedLayout = RemoteViews(packageName, R.layout.notification_weather_expanded)
        bindViewData(expandedLayout, temperature, location, condition, highLow, time, iconRes)

        // Clear existing views in container to avoid duplicates if reused (though new RemoteViews is fresh)
        expandedLayout.removeAllViews(R.id.hourly_forecast_container)

        // Bind Hourly Data (0 to 4)
        for (i in 0 until 5) {
            val hTime = prefs.getString("hourly${i}_time", "")
            if (hTime != null && hTime.isNotEmpty()) {
                 val hTemp = prefs.getString("hourly${i}_temp", "--") ?: "--"
                 val hCond = prefs.getString("hourly${i}_condition", "cloud") ?: "cloud"
                 val hIcon = getWeatherIcon(hCond.lowercase(), isNight)

                 val itemRemoteView = RemoteViews(packageName, R.layout.notification_hourly_item)
                 itemRemoteView.setTextViewText(R.id.hourly_time, hTime)
                 itemRemoteView.setTextViewText(R.id.hourly_temp, hTemp)
                 itemRemoteView.setImageViewResource(R.id.hourly_icon, hIcon)
                 
                 expandedLayout.addView(R.id.hourly_forecast_container, itemRemoteView)
            }
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_weather_cloudy)
            .setCustomContentView(notificationLayout)
            .setCustomBigContentView(expandedLayout)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
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

    private fun bindViewData(
        views: RemoteViews,
        temp: String,
        loc: String,
        cond: String,
        hl: String,
        time: String,
        icon: Int
    ) {
        views.setTextViewText(R.id.notif_temp, "$temp°")
        views.setTextViewText(R.id.notif_location, loc)
        views.setTextViewText(R.id.notif_condition, cond)
        views.setTextViewText(R.id.notif_high_low, "H/L: $hl")
        views.setTextViewText(R.id.notif_updated, "Updated $time")
        views.setImageViewResource(R.id.notif_icon, icon)
    }

    companion object {
        const val CHANNEL_ID = "WeatherNotificationChannel"
        private const val PREFS_NAME = "HomeWidgetPreferences"
    }
}
