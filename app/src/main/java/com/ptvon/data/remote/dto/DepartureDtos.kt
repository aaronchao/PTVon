package com.ptvon.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Response of `/v3/departures/route_type/{route_type}/stop/{stop_id}`.
 *
 * Expansions (routes / directions / runs) are returned as maps keyed by the
 * stringified id; request them with `expand=Route,Direction,Run`.
 */
@Serializable
data class DeparturesResponse(
    val departures: List<DepartureDto> = emptyList(),
    val routes: Map<String, RouteDto> = emptyMap(),
    val directions: Map<String, DirectionDto> = emptyMap(),
    val runs: Map<String, RunDto> = emptyMap(),
)

@Serializable
data class DepartureDto(
    @SerialName("stop_id") val stopId: Int,
    @SerialName("route_id") val routeId: Int,
    @SerialName("run_ref") val runRef: String? = null,
    @SerialName("direction_id") val directionId: Int,
    @SerialName("scheduled_departure_utc") val scheduledDepartureUtc: String? = null,
    @SerialName("estimated_departure_utc") val estimatedDepartureUtc: String? = null,
    @SerialName("at_platform") val atPlatform: Boolean = false,
    @SerialName("platform_number") val platformNumber: String? = null,
)

@Serializable
data class RouteDto(
    @SerialName("route_id") val routeId: Int,
    @SerialName("route_type") val routeType: Int,
    @SerialName("route_name") val routeName: String? = null,
    @SerialName("route_number") val routeNumber: String? = null,
)

@Serializable
data class DirectionDto(
    @SerialName("direction_id") val directionId: Int,
    @SerialName("direction_name") val directionName: String? = null,
)

@Serializable
data class RunDto(
    @SerialName("run_ref") val runRef: String? = null,
    @SerialName("destination_name") val destinationName: String? = null,
)
