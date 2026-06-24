package com.ptvon.domain

import com.ptvon.data.remote.dto.DeparturesResponse
import com.ptvon.domain.model.Departure
import com.ptvon.domain.model.RouteType
import java.time.Instant
import java.time.format.DateTimeParseException
import javax.inject.Inject

/**
 * Turns a raw [DeparturesResponse] into UI-ready [Departure]s.
 *
 * Real-time rule (per spec): prefer `estimated_departure_utc`; fall back to
 * `scheduled_departure_utc` when the estimate is null. Departures with neither
 * (or unparseable) timestamps are dropped rather than shown as wrong.
 *
 * Requires Java 8 time desugaring (`coreLibraryDesugaring`) for `java.time` on older APIs.
 */
class DepartureMapper @Inject constructor() {

    fun map(response: DeparturesResponse): List<Departure> =
        response.departures.mapNotNull { dto ->
            val epochMillis = parseUtc(dto.estimatedDepartureUtc)
                ?: parseUtc(dto.scheduledDepartureUtc)
                ?: return@mapNotNull null

            val route = response.routes[dto.routeId.toString()]
            val direction = response.directions[dto.directionId.toString()]
            val run = dto.runRef?.let { response.runs[it] }

            val routeType = route?.routeType
                ?.let { RouteType.fromApiValue(it) }
                ?: RouteType.BUS

            Departure(
                routeType = routeType,
                label = route?.routeNumber?.takeIf { it.isNotBlank() }
                    ?: route?.routeName.orEmpty(),
                destination = run?.destinationName
                    ?: direction?.directionName
                    ?: "—",
                platform = dto.platformNumber,
                departureEpochMillis = epochMillis,
                isLive = dto.estimatedDepartureUtc != null,
                routeId = dto.routeId,
                directionId = dto.directionId,
                flags = dto.flags.orEmpty(),
            )
        }.sortedBy { it.departureEpochMillis }

    private fun parseUtc(value: String?): Long? {
        if (value.isNullOrBlank()) return null
        return try {
            Instant.parse(value).toEpochMilli()
        } catch (_: DateTimeParseException) {
            null
        }
    }
}
