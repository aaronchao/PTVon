package com.ptvon.domain.model

/** A pinned stop and its upcoming departures — one PID "board" on the dashboard. */
data class StationBoard(
    val stopId: Int,
    val name: String,
    val suburb: String?,
    val routeType: RouteType,
    val departures: List<Departure>,
    val disruptions: List<Disruption> = emptyList(),
)
