package com.ptvon.core.time

import android.os.SystemClock
import java.util.concurrent.atomic.AtomicReference
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Authoritative "now" for the whole app.
 *
 * Requirement: *reliable countdowns under all conditions*. A naive countdown uses
 * `System.currentTimeMillis()`, but the device wall clock can be wrong, manually
 * changed, or skewed — which would make every "X min" silently incorrect.
 *
 * Instead we anchor to the server's time (captured from each API response's `Date`
 * header by [ServerTimeInterceptor]) and advance it with [SystemClock.elapsedRealtime],
 * a MONOTONIC clock that is immune to wall-clock changes and never moves backwards.
 *
 *   nowMillis = serverEpochAtAnchor + (elapsedRealtime() - elapsedRealtimeAtAnchor)
 *
 * Before any response is seen we fall back to the wall clock so the first paint
 * isn't blocked (supports the "time on screen within 3s" goal).
 */
@Singleton
class TimeSource @Inject constructor() {

    private data class Anchor(val serverEpochMillis: Long, val elapsedRealtimeAtAnchor: Long)

    private val anchor = AtomicReference<Anchor?>(null)

    /** Called by the network layer when a response carries a trustworthy `Date`. */
    fun syncTo(serverEpochMillis: Long) {
        anchor.set(Anchor(serverEpochMillis, SystemClock.elapsedRealtime()))
    }

    /** Best-available current epoch millis. */
    fun nowMillis(): Long {
        val a = anchor.get() ?: return System.currentTimeMillis()
        return a.serverEpochMillis + (SystemClock.elapsedRealtime() - a.elapsedRealtimeAtAnchor)
    }

    /** True once we've synced to server time at least once. */
    val isSynced: Boolean get() = anchor.get() != null
}
