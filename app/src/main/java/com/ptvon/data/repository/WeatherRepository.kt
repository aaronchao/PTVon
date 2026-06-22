package com.ptvon.data.repository

import com.ptvon.data.remote.WeatherApi
import com.ptvon.domain.WeatherAdvisor
import com.ptvon.domain.model.WeatherAdvice
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WeatherRepository @Inject constructor(
    private val weatherApi: WeatherApi,
    private val advisor: WeatherAdvisor,
) {
    /** Live real-feel advice for [latitude]/[longitude]. Null on failure (UI hides the bar). */
    suspend fun adviceFor(latitude: Double, longitude: Double): WeatherAdvice? =
        withContext(Dispatchers.IO) {
            runCatching {
                val response = weatherApi.current(latitude, longitude)
                advisor.advise(response)
            }.getOrNull()
        }
}
