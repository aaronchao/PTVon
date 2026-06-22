package com.ptvon.data.repository

import com.ptvon.data.remote.PtvApi
import com.ptvon.data.remote.PtvMode
import com.ptvon.domain.model.PinnedStop
import com.ptvon.domain.model.RouteType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StopSearchRepository @Inject constructor(
    private val api: PtvApi,
) {
    private val isDemoMode: Boolean
        get() = PtvMode.isDemo

    /** Search trains/trams/buses for [term]. Returns pinnable stops. */
    suspend fun search(term: String): List<PinnedStop> {
        if (term.isBlank()) return emptyList()
        if (isDemoMode) return demoResults(term)

        return withContext(Dispatchers.IO) {
            runCatching {
                api.search(term.trim(), routeTypes = listOf(0, 1, 2))
                    .stops
                    .map {
                        PinnedStop(
                            stopId = it.stopId,
                            name = it.stopName.trim(),
                            suburb = it.stopSuburb?.trim(),
                            routeTypeValue = it.routeType,
                        )
                    }
                    .distinctBy { it.stopId }
                    .take(30)
            }.getOrDefault(emptyList())
        }
    }

    private fun demoResults(term: String): List<PinnedStop> =
        DEMO_STOPS.filter { it.name.contains(term.trim(), ignoreCase = true) }

    private companion object {
        val DEMO_STOPS = listOf(
            PinnedStop(1071, "Flinders Street", "Melbourne", RouteType.TRAIN.apiValue),
            PinnedStop(1181, "Southern Cross", "Melbourne", RouteType.TRAIN.apiValue),
            PinnedStop(1120, "Melbourne Central", "Melbourne", RouteType.TRAIN.apiValue),
            PinnedStop(1162, "Richmond", "Richmond", RouteType.TRAIN.apiValue),
            PinnedStop(2503, "Bourke St / Spencer St", "Melbourne", RouteType.TRAM.apiValue),
            PinnedStop(2170, "Collins St / Swanston St", "Melbourne", RouteType.TRAM.apiValue),
            PinnedStop(13950, "Lonsdale St / Elizabeth St", "Melbourne", RouteType.BUS.apiValue),
        )
    }
}
