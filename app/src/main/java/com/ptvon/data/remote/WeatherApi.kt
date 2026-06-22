package com.ptvon.data.remote

import com.ptvon.data.remote.dto.WeatherResponse
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * Open-Meteo forecast API — keyless and free. Uses the @Named("weather") Retrofit
 * (plain client, NO PTV auth interceptor).
 */
interface WeatherApi {

    @GET("v1/forecast")
    suspend fun current(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("current") current: String =
            "temperature_2m,apparent_temperature,relative_humidity_2m," +
                "precipitation,weather_code,wind_speed_10m,is_day",
        @Query("hourly") hourly: String = "temperature_2m,weather_code,is_day",
        @Query("forecast_days") forecastDays: Int = 2,
        @Query("timezone") timezone: String = "auto",
    ): WeatherResponse
}
