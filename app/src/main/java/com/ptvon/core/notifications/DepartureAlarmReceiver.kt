package com.ptvon.core.notifications

import android.Manifest
import android.app.Notification
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Fired by AlarmManager at each lead time (10/5/1 min) before the tracked
 * departure. Posts a high-priority countdown notification.
 */
class DepartureAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val minutes = intent.getIntExtra(EXTRA_MINUTES, 0)
        val stopName = intent.getStringExtra(EXTRA_STOP_NAME) ?: "your stop"
        val line = intent.getStringExtra(EXTRA_LINE).orEmpty()
        val destination = intent.getStringExtra(EXTRA_DESTINATION).orEmpty()
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 1)

        NotificationChannels.ensureChannels(context)

        val title = if (minutes <= 1) "Departing now — go!" else "$minutes min to departure"
        val service = listOfNotNull(line.ifBlank { null }, destination.ifBlank { null })
            .joinToString(" → ")
        val text = buildString {
            if (service.isNotBlank()) append(service).append(" · ")
            append(stopName)
        }

        val notification: Notification = NotificationCompat.Builder(context, NotificationChannels.DEPARTURE_ALERTS)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .build()

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(notifId, notification)
        }
    }

    companion object {
        const val EXTRA_MINUTES = "extra_minutes"
        const val EXTRA_STOP_NAME = "extra_stop_name"
        const val EXTRA_LINE = "extra_line"
        const val EXTRA_DESTINATION = "extra_destination"
        const val EXTRA_NOTIF_ID = "extra_notif_id"
    }
}
