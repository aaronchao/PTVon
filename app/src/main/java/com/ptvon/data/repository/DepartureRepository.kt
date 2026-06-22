package com.ptvon.data.repository

import com.ptvon.core.time.TimeSource
import com.ptvon.data.remote.PtvApi
import com.ptvon.data.remote.PtvMode
import com.ptvon.domain.DepartureMapper
import com.ptvon.domain.model.Departure
import com.ptvon.domain.model.Disruption
import com.ptvon.domain.model.PinnedStop
import com.ptvon.domain.model.RouteType
import com.ptvon.domain.model.StationBoard
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.absoluteValue
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Builds the departure boards for the user's pinned stops.
 *
 * With PTV credentials it fetches live departures per stop; in demo mode it
 * synthesises plausible departures anchored to the real clock so the dashboard
 * is populated and countdowns tick.
 */
@Singleton
class DepartureRepository @Inject constructor(
    private val api: PtvApi,
    private val mapper: DepartureMapper,
    private val timeSource: TimeSource,
) {
    val isDemoMode: Boolean
        get() = PtvMode.isDemo

    suspend fun loadBoards(pins: List<PinnedStop>): List<StationBoard> {
        val source = if (pins.isEmpty() && isDemoMode) DEMO_PINS else pins
        if (source.isEmpty()) return emptyList()

        return withContext(Dispatchers.IO) {
            source.map { pin ->
                val departures = if (isDemoMode) {
                    sampleDepartures(pin)
                } else {
                    runCatching {
                        mapper.map(api.departures(pin.routeType.apiValue, pin.stopId))
                    }.getOrElse { emptyList() }
                }.take(MAX_DEPARTURES_PER_BOARD)
                val disruptions = if (isDemoMode) demoDisruptions(pin) else fetchDisruptions(pin)
                StationBoard(pin.stopId, pin.name, pin.suburb, pin.routeType, departures, disruptions)
            }
        }
    }

    private suspend fun fetchDisruptions(pin: PinnedStop): List<Disruption> =
        runCatching {
            api.disruptionsForStop(pin.stopId).disruptions.values
                .flatten()
                .mapNotNull { dto ->
                    val title = dto.title?.trim().orEmpty()
                    if (title.isBlank()) return@mapNotNull null
                    Disruption(
                        title = title,
                        description = dto.description?.trim()?.takeIf { it.isNotBlank() },
                        isPlanned = dto.status.equals("Planned", ignoreCase = true),
                    )
                }
                .distinctBy { it.title }
                .take(MAX_DISRUPTIONS)
        }.getOrElse { emptyList() }

    /** Next live departure time for a stop, used to schedule alerts. */
    suspend fun nextDepartureMillis(pin: PinnedStop): Long? =
        loadBoards(listOf(pin)).firstOrNull()?.departures?.firstOrNull()?.departureEpochMillis

    // --- Demo data ---------------------------------------------------------

    private fun sampleDepartures(pin: PinnedStop): List<Departure> {
        val now = timeSource.nowMillis()
        // Deterministic offsets per stop so the board is stable between refreshes.
        val seed = (pin.stopId % 5).absoluteValue
        val offsets = listOf(2 + seed, 6 + seed, 12 + seed)
        val destinations = DEMO_DESTINATIONS[pin.routeType] ?: listOf("City")
        return offsets.mapIndexed { i, min ->
            Departure(
                routeType = pin.routeType,
                label = DEMO_LABELS[pin.routeType]?.getOrNull(i % 3) ?: "",
                destination = destinations[i % destinations.size],
                platform = if (pin.routeType == RouteType.TRAIN) (i + 1).toString() else null,
                departureEpochMillis = now + min * 60_000L,
                isLive = i < 2,
            )
        }
    }

    private fun demoDisruptions(pin: PinnedStop): List<Disruption> = when (pin.routeType) {
        RouteType.TRAIN -> listOf(
            Disruption(
                title = "Minor delays of up to 10 min due to a signal fault near the city.",
                description = "Allow extra travel time. Services are gradually returning to normal.",
                isPlanned = false,
            ),
        )
        RouteType.TRAM -> listOf(
            Disruption(
                title = "Route 86 diverted around Bourke St between 9pm–4am for track works.",
                description = null,
                isPlanned = true,
            ),
        )
        else -> emptyList()
    }

    private companion object {
        const val MAX_DISRUPTIONS = 3
        const val MAX_DEPARTURES_PER_BOARD = 3 // keep 3 stations glanceable on one screen

        val DEMO_PINS = listOf(
            PinnedStop(1071, "Flinders Street", "Melbourne", RouteType.TRAIN.apiValue),
            PinnedStop(2503, "Bourke St / Spencer St", "Melbourne", RouteType.TRAM.apiValue),
            PinnedStop(13950, "Lonsdale St / Elizabeth St", "Melbourne", RouteType.BUS.apiValue),
        )

        val DEMO_DESTINATIONS = mapOf(
            RouteType.TRAIN to listOf("Mernda", "Hurstbridge", "Craigieburn"),
            RouteType.TRAM to listOf("Bundoora RMIT", "East Brunswick", "Melbourne Uni"),
            RouteType.BUS to listOf("Bulleen", "Doncaster SC", "Box Hill"),
        )
        val DEMO_LABELS = mapOf(
            RouteType.TRAIN to listOf("Mernda", "Hurstbridge", "Craigieburn"),
            RouteType.TRAM to listOf("86", "96", "1"),
            RouteType.BUS to listOf("200", "207", "302"),
        )
    }
}
