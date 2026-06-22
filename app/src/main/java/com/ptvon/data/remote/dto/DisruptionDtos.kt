package com.ptvon.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Response of `/v3/disruptions/stop/{stop_id}`. PTV groups disruptions by mode under
 * arbitrary keys (general, metro_train, metro_tram, metro_bus, regional_train, ...),
 * so we model the container as a map and flatten it.
 */
@Serializable
data class DisruptionsResponse(
    val disruptions: Map<String, List<DisruptionDto>> = emptyMap(),
)

@Serializable
data class DisruptionDto(
    @SerialName("disruption_id") val id: Long? = null,
    val title: String? = null,
    val description: String? = null,
    val url: String? = null,
    @SerialName("disruption_status") val status: String? = null,
    @SerialName("disruption_type") val type: String? = null,
)
