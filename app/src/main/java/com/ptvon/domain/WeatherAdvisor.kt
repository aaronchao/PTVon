package com.ptvon.domain

import com.ptvon.data.remote.dto.HourlyWeatherDto
import com.ptvon.data.remote.dto.WeatherResponse
import com.ptvon.domain.model.HourForecast
import com.ptvon.domain.model.WeatherAdvice
import com.ptvon.domain.model.WeatherCondition
import javax.inject.Inject
import kotlin.math.roundToInt

/**
 * Pure mapping from current conditions to "what to wear / bring" guidance.
 *
 * Driven by the *real feel* (apparent) temperature, not the raw thermometer reading —
 * a 12° morning with a stiff wind asks for a coat, and this reflects that. Tuned for
 * Melbourne's volatility ("four seasons in one day"): when rain is even plausible we
 * nudge the commuter to carry a brolly.
 *
 * No I/O, no Android — trivially unit-testable.
 */
class WeatherAdvisor @Inject constructor() {

    fun advise(response: WeatherResponse): WeatherAdvice {
        val current = response.current
        val feel = current.apparentTemperatureC.roundToInt()
        val condition = WeatherCondition.fromWmoCode(current.weatherCode)
        val wet = condition in WET_CONDITIONS || current.precipitationMm >= 0.1
        val windy = current.windSpeedKmh >= 30.0

        val wear = buildList {
            when {
                feel <= 4 -> { add("Heavy coat"); add("Beanie & gloves"); add("Thermal layer") }
                feel <= 9 -> { add("Warm coat"); add("Scarf"); add("Long sleeves") }
                feel <= 14 -> { add("Jacket"); add("Light layer underneath") }
                feel <= 19 -> { add("Light jacket or jumper") }
                feel <= 25 -> { add("T-shirt"); add("Comfortable clothes") }
                else -> { add("Light, breathable clothing"); add("Hat") }
            }
            if (windy && feel <= 19) add("Windproof outer layer")
        }

        val bring = buildList {
            if (wet) add("Umbrella")
            if (feel >= 26) { add("Water bottle"); add("Sunscreen") }
            else if (condition == WeatherCondition.CLEAR && current.isDay == 1) add("Sunglasses")
            if (feel in 10..18) add("Layers (it may change)") // Melbourne hedge
        }

        return WeatherAdvice(
            realFeelC = feel,
            actualC = current.temperatureC.roundToInt(),
            condition = condition,
            isDay = current.isDay == 1,
            headline = headline(feel, condition, wet),
            wear = wear,
            bring = bring,
            forecast = buildForecast(current.time, response.hourly),
        )
    }

    /** The next 6 hours after the current hour, for the mini forecast strip. */
    private fun buildForecast(currentTime: String, hourly: HourlyWeatherDto?): List<HourForecast> {
        if (hourly == null || hourly.time.isEmpty()) return emptyList()
        val currentHourKey = currentTime.take(13) // "2026-06-20T22"
        var start = hourly.time.indexOfFirst { it.take(13) == currentHourKey }
        if (start < 0) start = hourly.time.indexOfFirst { it >= currentTime }
        if (start < 0) start = 0
        val from = start + 1
        return (from until minOf(from + 6, hourly.time.size)).map { i ->
            HourForecast(
                label = hourLabel(hourly.time[i]),
                tempC = hourly.temperatureC.getOrElse(i) { 0.0 }.roundToInt(),
                condition = WeatherCondition.fromWmoCode(hourly.weatherCode.getOrElse(i) { 0 }),
                isDay = hourly.isDay.getOrElse(i) { 1 } == 1,
            )
        }
    }

    private fun hourLabel(iso: String): String {
        val hour = iso.substringAfter('T').take(2).toIntOrNull() ?: return ""
        val h12 = when (val h = hour % 12) { 0 -> 12; else -> h }
        return "$h12${if (hour < 12) "am" else "pm"}"
    }

    private fun headline(feel: Int, condition: WeatherCondition, wet: Boolean): String = when {
        wet && feel <= 9 -> "Feels $feel° & wet — rug up, take a brolly"
        wet -> "Feels $feel° — grab a brolly"
        feel <= 4 -> "Feels $feel° — bitterly cold, layer up"
        feel <= 9 -> "Feels $feel° — rug up"
        feel <= 14 -> "Feels $feel° — a jacket today"
        feel <= 19 -> "Feels $feel° — mild, light layer"
        feel <= 25 -> "Feels $feel° — comfortable"
        else -> "Feels $feel° — hot, stay cool"
    }

    private companion object {
        val WET_CONDITIONS = setOf(
            WeatherCondition.RAIN,
            WeatherCondition.SHOWERS,
            WeatherCondition.STORM,
            WeatherCondition.SNOW,
        )
    }
}
