package com.ptvon.domain.model

import kotlinx.serialization.Serializable

/** A stop the user has pinned to the dashboard (persisted in DataStore). */
@Serializable
data class PinnedStop(
    val stopId: Int,
    val name: String,
    val suburb: String?,
    val routeTypeValue: Int,
) {
    val routeType: RouteType get() = RouteType.fromApiValue(routeTypeValue)

    companion object {
        const val MAX_PINS = 4
    }
}
