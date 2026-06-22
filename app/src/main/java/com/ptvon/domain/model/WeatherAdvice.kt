package com.ptvon.domain.model

/**
 * UI-ready weather guidance derived from the *real feel* (apparent) temperature
 * plus precipitation and wind. Kept deliberately short to stay uncluttered.
 */
data class WeatherAdvice(
    val realFeelC: Int,
    val actualC: Int,
    val condition: WeatherCondition,
    val isDay: Boolean,
    val headline: String,        // one glanceable line, e.g. "Feels 6° — rug up"
    val wear: List<String>,      // clothing suggestions
    val bring: List<String>,     // items to carry
    val forecast: List<HourForecast> = emptyList(), // next ~6 hours
)

/** A single upcoming hour for the mini forecast strip. */
data class HourForecast(
    val label: String,           // e.g. "11pm"
    val tempC: Int,
    val condition: WeatherCondition,
    val isDay: Boolean,
)

enum class WeatherCondition(val label: String) {
    CLEAR("Clear"),
    CLOUDY("Cloudy"),
    FOG("Fog"),
    RAIN("Rain"),
    SHOWERS("Showers"),
    SNOW("Snow"),
    STORM("Storm");

    companion object {
        /** Map a WMO weather code (Open-Meteo) to a coarse condition. */
        fun fromWmoCode(code: Int): WeatherCondition = when (code) {
            0 -> CLEAR
            1, 2, 3 -> CLOUDY
            45, 48 -> FOG
            51, 53, 55, 56, 57, 61, 63, 65, 66, 67 -> RAIN
            71, 73, 75, 77, 85, 86 -> SNOW
            80, 81, 82 -> SHOWERS
            95, 96, 99 -> STORM
            else -> CLOUDY
        }
    }
}
