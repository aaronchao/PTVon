package com.ptvon.ui.dashboard

import com.ptvon.domain.model.PinnedStop
import com.ptvon.domain.model.StationBoard
import com.ptvon.domain.model.WeatherAdvice

data class DashboardUiState(
    val isLoading: Boolean = true,
    val isDemoMode: Boolean = false,
    val weather: WeatherAdvice? = null,
    val pins: List<PinnedStop> = emptyList(),
    val boards: List<StationBoard> = emptyList(),
    /** The single tracked stop receiving alerts, or null. */
    val currentStopId: Int? = null,
    /** Authoritative current time; UI computes each countdown as departure - nowMillis. */
    val nowMillis: Long = System.currentTimeMillis(),
) {
    val canAddMore: Boolean get() = pins.size < PinnedStop.MAX_PINS
    val hasPins: Boolean get() = pins.isNotEmpty() || (isDemoMode && boards.isNotEmpty())
}
