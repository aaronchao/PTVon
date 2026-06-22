package com.ptvon.core.notifications

import android.content.Context
import androidx.core.content.ContextCompat
import com.ptvon.domain.model.StationBoard
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Starts/stops the [TrackingService] live lock-screen countdown for the tracked stop.
 */
@Singleton
class TrackingController @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    fun start(board: StationBoard) {
        val next = board.departures.firstOrNull() ?: run { stop(); return }
        val intent = TrackingService.startIntent(
            context = context,
            stopName = board.name,
            line = next.label,
            destination = next.destination,
            departureAt = next.departureEpochMillis,
        )
        ContextCompat.startForegroundService(context, intent)
    }

    fun stop() {
        context.startService(TrackingService.stopIntent(context))
    }
}
