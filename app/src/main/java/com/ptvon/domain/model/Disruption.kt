package com.ptvon.domain.model

/** A delay/service alert affecting a stop. Trimmed to what the glanceable UI needs. */
data class Disruption(
    val title: String,
    val description: String?,
    val isPlanned: Boolean,
)
