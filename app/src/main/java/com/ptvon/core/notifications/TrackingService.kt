package com.ptvon.core.notifications

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.ptvon.MainActivity

/**
 * Foreground service that shows an ongoing **live countdown** on the lock screen for
 * the tracked departure. The OS drives the second-by-second countdown via a count-down
 * chronometer ([NotificationCompat.setChronometerCountDown]) anchored to the departure
 * time, so we don't have to wake the app every second.
 *
 * On Android 16+ the notification is also flagged `FLAG_PROMOTED_ONGOING` (set
 * reflectively to avoid needing compileSdk 36) so it surfaces as a promoted Live Update.
 */
class TrackingService : Service() {

    override fun onBind(intent: Intent): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }

        val stopName = intent?.getStringExtra(EXTRA_STOP_NAME) ?: "Tracked stop"
        val line = intent?.getStringExtra(EXTRA_LINE).orEmpty()
        val destination = intent?.getStringExtra(EXTRA_DESTINATION).orEmpty()
        val departureAt = intent?.getLongExtra(EXTRA_DEPARTURE_AT, 0L) ?: 0L

        val notification = buildNotification(stopName, line, destination, departureAt)
        ServiceCompat.startForeground(
            this,
            NOTIF_ID,
            notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0,
        )
        return START_STICKY
    }

    private fun buildNotification(
        stopName: String,
        line: String,
        destination: String,
        departureAt: Long,
    ): Notification {
        NotificationChannels.ensureChannels(this)

        val service = listOfNotNull(line.ifBlank { null }, destination.ifBlank { null })
            .joinToString(" → ")
        val contentText = if (service.isNotBlank()) "$service · departs in" else "Departs in"

        val openApp = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(this, NotificationChannels.LIVE_COUNTDOWN)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle(stopName)
            .setContentText(contentText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setContentIntent(openApp)
            .setColorized(true)

        // Live countdown handled by the OS clock.
        if (departureAt > 0L) {
            builder.setWhen(departureAt)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setShowWhen(true)
        }

        val notification = builder.build()
        promoteIfSupported(notification)
        return notification
    }

    /** Android 16 Live Update promotion, applied reflectively (constant is API 36). */
    private fun promoteIfSupported(notification: Notification) {
        if (Build.VERSION.SDK_INT >= 36) {
            runCatching {
                val flag = Notification::class.java.getField("FLAG_PROMOTED_ONGOING").getInt(null)
                notification.flags = notification.flags or flag
            }
        }
    }

    private fun stopForegroundCompat() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
    }

    companion object {
        private const val NOTIF_ID = 4242
        const val ACTION_STOP = "com.ptvon.action.STOP_TRACKING"
        const val EXTRA_STOP_NAME = "extra_stop_name"
        const val EXTRA_LINE = "extra_line"
        const val EXTRA_DESTINATION = "extra_destination"
        const val EXTRA_DEPARTURE_AT = "extra_departure_at"

        fun startIntent(
            context: Context,
            stopName: String,
            line: String,
            destination: String,
            departureAt: Long,
        ) = Intent(context, TrackingService::class.java).apply {
            putExtra(EXTRA_STOP_NAME, stopName)
            putExtra(EXTRA_LINE, line)
            putExtra(EXTRA_DESTINATION, destination)
            putExtra(EXTRA_DEPARTURE_AT, departureAt)
        }

        fun stopIntent(context: Context) =
            Intent(context, TrackingService::class.java).apply { action = ACTION_STOP }
    }
}
