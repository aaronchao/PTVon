package com.ptvon.data.remote

import com.ptvon.core.time.TimeSource
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Captures the server clock from every successful response's `Date` header and
 * feeds it to [TimeSource], keeping the app's notion of "now" anchored to a
 * trustworthy source rather than the (possibly wrong) device wall clock.
 */
@Singleton
class ServerTimeInterceptor @Inject constructor(
    private val timeSource: TimeSource,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val response = chain.proceed(chain.request())
        // OkHttp parses the RFC 1123 `Date` header into a Date for us.
        response.headers.getDate("Date")?.let { date ->
            timeSource.syncTo(date.time)
        }
        return response
    }
}
