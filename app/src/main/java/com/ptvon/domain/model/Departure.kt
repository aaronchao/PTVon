package com.ptvon.domain.model

/**
 * A single upcoming service at a pinned stop — already resolved (route/destination
 * names filled in) and brand-coloured. UI-ready, framework-free.
 *
 * @param departureEpochMillis the time to count down to (estimated if live, else scheduled).
 * @param isLive true when [departureEpochMillis] came from `estimated_departure_utc`.
 */
data class Departure(
    val routeType: RouteType,
    val label: String,            // line name or route number, e.g. "Mernda" or "19"
    val destination: String,      // direction/destination, e.g. "City (Flinders Street)"
    val platform: String?,
    val departureEpochMillis: Long,
    val isLive: Boolean,
) {
    /**
     * Minutes until departure given the authoritative [nowMillis] (from TimeSource).
     * Returns 0 for "due now" and never goes negative.
     */
    fun minutesUntil(nowMillis: Long): Int {
        val deltaMs = departureEpochMillis - nowMillis
        if (deltaMs <= DUE_THRESHOLD_MS) return 0
        // Round to nearest minute so a 4:31 wait reads "5 min", matching PID boards.
        return ((deltaMs + 30_000L) / 60_000L).toInt()
    }

    fun isDue(nowMillis: Long): Boolean =
        departureEpochMillis - nowMillis <= DUE_THRESHOLD_MS

    private companion object {
        const val DUE_THRESHOLD_MS = 30_000L
    }
}
