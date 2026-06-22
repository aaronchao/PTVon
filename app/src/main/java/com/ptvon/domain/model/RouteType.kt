package com.ptvon.domain.model

/**
 * PTV `route_type` identifiers, paired with their canonical brand colours
 * (used by the PID-style UI). Colours are stored as ARGB longs so the domain
 * layer stays Compose-free; the UI maps them to `Color(...)`.
 */
enum class RouteType(val apiValue: Int, val displayName: String, val brandColor: Long) {
    TRAIN(0, "Train", 0xFF3F7BFF),    // friendly blue
    TRAM(1, "Tram", 0xFF35C07A),      // friendly green
    BUS(2, "Bus", 0xFFFF9D4D),        // friendly orange
    VLINE(3, "V/Line", 0xFFA06CFF),   // friendly purple
    NIGHT_BUS(4, "Night Bus", 0xFFFF9D4D);

    companion object {
        fun fromApiValue(value: Int): RouteType =
            entries.firstOrNull { it.apiValue == value } ?: BUS
    }
}
