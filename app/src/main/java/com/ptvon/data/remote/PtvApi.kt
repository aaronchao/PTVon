package com.ptvon.data.remote

import com.ptvon.data.remote.dto.DeparturesResponse
import com.ptvon.data.remote.dto.DisruptionsResponse
import com.ptvon.data.remote.dto.SearchResponse
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

/**
 * PTV Timetable API v3. Auth params (`devid`, `signature`) are injected by
 * [PtvAuthInterceptor] — do NOT add them here.
 */
interface PtvApi {

    /** Search stops/stations to pin. `routeTypes` narrows results (0=train,1=tram,2=bus...). */
    @GET("v3/search/{term}")
    suspend fun search(
        @Path("term") term: String,
        @Query("route_types") routeTypes: List<Int>? = null,
        @Query("include_outlets") includeOutlets: Boolean = false,
    ): SearchResponse

    /**
     * Live departures for a pinned stop.
     * @param maxResults keep small (e.g. 4) — the PID UI is deliberately glanceable.
     * @param expand resolves route/direction/run names in one round-trip.
     */
    @GET("v3/departures/route_type/{routeType}/stop/{stopId}")
    suspend fun departures(
        @Path("routeType") routeType: Int,
        @Path("stopId") stopId: Int,
        @Query("max_results") maxResults: Int = 4,
        @Query("expand") expand: List<String> = listOf("Route", "Direction", "Run"),
        @Query("include_cancelled") includeCancelled: Boolean = false,
    ): DeparturesResponse

    /** Current delays/service alerts affecting a stop. */
    @GET("v3/disruptions/stop/{stopId}")
    suspend fun disruptionsForStop(
        @Path("stopId") stopId: Int,
        @Query("disruption_status") status: String = "current",
    ): DisruptionsResponse
}
