package com.ptvon.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Response of `/v3/search/{search_term}` — only the `stops` block is needed for pinning. */
@Serializable
data class SearchResponse(
    val stops: List<StopResultDto> = emptyList(),
)

@Serializable
data class StopResultDto(
    @SerialName("stop_id") val stopId: Int,
    @SerialName("stop_name") val stopName: String,
    @SerialName("route_type") val routeType: Int,
    @SerialName("stop_suburb") val stopSuburb: String? = null,
    @SerialName("stop_latitude") val latitude: Double? = null,
    @SerialName("stop_longitude") val longitude: Double? = null,
)
