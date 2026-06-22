package com.ptvon.core.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.ptvon.domain.model.Departure
import com.ptvon.domain.model.StationBoard
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Schedules exact alarms at 10/5/1 minutes before the tracked stop's next
 * departure. WorkManager isn't precise enough for to-the-minute transit alerts,
 * so we use AlarmManager exact alarms (falling back to inexact if the OS denies
 * exact-alarm permission).
 */
@Singleton
class AlertScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    private val leadMinutes = listOf(10, 5, 1)

    /** Cancel any existing alerts and schedule fresh ones for [board]'s next departure. */
    fun scheduleFor(board: StationBoard) {
        cancelAll()
        val next: Departure = board.departures.firstOrNull() ?: return
        val now = System.currentTimeMillis()

        leadMinutes.forEach { lead ->
            val fireAt = next.departureEpochMillis - lead * 60_000L
            if (fireAt <= now) return@forEach
            val pending = pendingIntent(lead, board, next)
            scheduleExact(fireAt, pending)
        }
    }

    fun cancelAll() {
        leadMinutes.forEach { lead ->
            alarmManager?.cancel(pendingIntent(lead, board = null, departure = null))
        }
    }

    private fun scheduleExact(triggerAtMillis: Long, pending: PendingIntent) {
        val am = alarmManager ?: return
        val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            am.canScheduleExactAlarms()
        } else true

        if (canExact) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        }
    }

    private fun pendingIntent(lead: Int, board: StationBoard?, departure: Departure?): PendingIntent {
        val intent = Intent(context, DepartureAlarmReceiver::class.java).apply {
            action = "$ACTION_PREFIX$lead"
            putExtra(DepartureAlarmReceiver.EXTRA_MINUTES, lead)
            putExtra(DepartureAlarmReceiver.EXTRA_NOTIF_ID, NOTIF_BASE + lead)
            board?.let { putExtra(DepartureAlarmReceiver.EXTRA_STOP_NAME, it.name) }
            departure?.let {
                putExtra(DepartureAlarmReceiver.EXTRA_LINE, it.label)
                putExtra(DepartureAlarmReceiver.EXTRA_DESTINATION, it.destination)
            }
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_BASE + lead,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private companion object {
        const val ACTION_PREFIX = "com.ptvon.ALERT_"
        const val REQUEST_BASE = 7100
        const val NOTIF_BASE = 7200
    }
}
