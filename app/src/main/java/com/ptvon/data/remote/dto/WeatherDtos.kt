package com.ptvon.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Response of Open-Meteo `/v1/forecast` with `current` + `hourly` blocks. */
@Serializable
data class WeatherResponse(
    val current: CurrentWeatherDto,
    val hourly: HourlyWeatherDto? = null,
)

@Serializable
data class CurrentWeatherDto(
    val time: String = "",
    @SerialName("temperature_2m") val temperatureC: Double,
    @SerialName("apparent_temperature") val apparentTemperatureC: Double, // "real feel"
    @SerialName("relative_humidity_2m") val humidity: Int = 0,
    @SerialName("precipitation") val precipitationMm: Double = 0.0,
    @SerialName("weather_code") val weatherCode: Int = 0,
    @SerialName("wind_speed_10m") val windSpeedKmh: Double = 0.0,
    @SerialName("is_day") val isDay: Int = 1,
)

@Serializable
data class HourlyWeatherDto(
    val time: List<String> = emptyList(),
    @SerialName("temperature_2m") val temperatureC: List<Double> = emptyList(),
    @SerialName("weather_code") val weatherCode: List<Int> = emptyList(),
    @SerialName("is_day") val isDay: List<Int> = emptyList(),
)
