package com.ptvon.di

import com.ptvon.BuildConfig
import com.ptvon.data.remote.PtvApi
import com.ptvon.data.remote.PtvAuthInterceptor
import com.ptvon.data.remote.ServerTimeInterceptor
import com.ptvon.data.remote.WeatherApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Named
import javax.inject.Singleton

/**
 * Hilt module providing the networking stack for the PTV Timetable API.
 *
 * Graph: credentials (@Named) -> PtvAuthInterceptor -> OkHttpClient -> Retrofit.
 * The auth interceptor is added LAST so it signs the final, fully-built URL
 * (after any other interceptor has mutated it).
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    private const val PTV_DIRECT_URL = "https://timetableapi.ptv.vic.gov.au/"
    private const val WEATHER_BASE_URL = "https://api.open-meteo.com/"

    /** Proxy base URL if configured, else PTV directly. Always ends in '/'. */
    private fun ptvBaseUrl(): String {
        val proxy = BuildConfig.PTV_PROXY_URL
        return if (proxy.isNotBlank()) proxy.trimEnd('/') + "/" else PTV_DIRECT_URL
    }

    /** Developer id, injected from BuildConfig (sourced from local.properties / CI secrets). */
    @Provides
    @Named("ptvDevId")
    fun provideDevId(): String = BuildConfig.PTV_DEV_ID

    /** Developer signing key, injected from BuildConfig. */
    @Provides
    @Named("ptvApiKey")
    fun provideApiKey(): String = BuildConfig.PTV_API_KEY

    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true   // PTV responses carry fields we don't model
        explicitNulls = false
        coerceInputValues = true
    }

    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor =
        HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

    /**
     * Base client shared by every backend: logging + server-time capture, but NO
     * PTV auth. The server-time interceptor keeps [com.ptvon.core.time.TimeSource]
     * anchored from whichever backend responds (PTV or Open-Meteo both send `Date`).
     */
    @Provides
    @Singleton
    @Named("baseClient")
    fun provideBaseClient(
        serverTimeInterceptor: ServerTimeInterceptor,
        loggingInterceptor: HttpLoggingInterceptor,
    ): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .addInterceptor(serverTimeInterceptor)
        .addInterceptor(loggingInterceptor)
        .build()

    /** PTV client = base client + auth interceptor (added last so it signs the final URL). */
    @Provides
    @Singleton
    @Named("ptvClient")
    fun providePtvClient(
        @Named("baseClient") base: OkHttpClient,
        authInterceptor: PtvAuthInterceptor,
    ): OkHttpClient = base.newBuilder()
        .addInterceptor(authInterceptor)
        .build()

    private fun retrofit(baseUrl: String, client: OkHttpClient, json: Json): Retrofit =
        Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()

    @Provides
    @Singleton
    fun providePtvApi(
        @Named("ptvClient") client: OkHttpClient,
        json: Json,
    ): PtvApi = retrofit(ptvBaseUrl(), client, json).create(PtvApi::class.java)

    @Provides
    @Singleton
    fun provideWeatherApi(
        @Named("baseClient") client: OkHttpClient,
        json: Json,
    ): WeatherApi = retrofit(WEATHER_BASE_URL, client, json).create(WeatherApi::class.java)
}
