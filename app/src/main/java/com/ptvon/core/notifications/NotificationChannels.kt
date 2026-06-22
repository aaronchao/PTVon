package com.ptvon.core.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

object NotificationChannels {
    const val DEPARTURE_ALERTS = "departure_alerts"
    const val LIVE_COUNTDOWN = "live_countdown"

    fun ensureChannels(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return

        val alerts = NotificationChannel(
            DEPARTURE_ALERTS,
            "Departure alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Countdown alerts for your tracked stop"
            enableVibration(true)
        }

        // Low importance: the ongoing live banner should be quiet (no sound/vibration).
        val live = NotificationChannel(
            LIVE_COUNTDOWN,
            "Live countdown",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Ongoing lock-screen countdown for the tracked departure"
            setShowBadge(false)
        }

        manager.createNotificationChannels(listOf(alerts, live))
    }
}
