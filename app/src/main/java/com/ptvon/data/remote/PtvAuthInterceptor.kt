package com.ptvon.data.remote

import okhttp3.Interceptor
import okhttp3.Response
import java.util.Locale
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import javax.inject.Inject
import javax.inject.Named
import javax.inject.Singleton

/**
 * Appends PTV Timetable API v3 authentication to every outgoing request.
 *
 * PTV auth requires two URL params:
 *  - `devid`     : the developer id issued by PTV.
 *  - `signature` : HMAC-SHA1 of the request **path + query** (NOT the full URL,
 *                  NOT including the host), keyed with the developer key, hex-encoded.
 *
 * Critical ordering rule enforced here:
 *  1. Append `devid` to the query FIRST.
 *  2. Build the signing message from the path + the now-devid-bearing query.
 *     The message must start with the leading '/', e.g. "/v3/departures/...?...&devid=1234567".
 *  3. HMAC-SHA1(message) with the developer key, hex-encode, append as `signature`.
 *
 * Signing the host or signing before `devid` is appended are the two most common
 * causes of a 403 from PTV — both are avoided below.
 */
@Singleton
class PtvAuthInterceptor @Inject constructor(
    @Named("ptvDevId") private val devId: String,
    @Named("ptvApiKey") private val apiKey: String,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()

        // Demo mode: no credentials configured — pass through unsigned. PTV will reject,
        // and the repository falls back to sample data, so the app still runs.
        if (devId.isBlank() || apiKey.isBlank()) {
            return chain.proceed(original)
        }

        val originalUrl = original.url

        // 1. Append devid before signing.
        val urlWithDevId = originalUrl.newBuilder()
            .setQueryParameter("devid", devId)
            .build()

        // 2. Build the message to sign: encoded path + "?" + encoded query.
        //    encodedPath already includes the leading '/'.
        val message = buildString {
            append(urlWithDevId.encodedPath)
            urlWithDevId.encodedQuery?.let { query ->
                append('?')
                append(query)
            }
        }

        // 3. Sign and append.
        val signature = hmacSha1(message, apiKey)
        val signedUrl = urlWithDevId.newBuilder()
            .addQueryParameter("signature", signature)
            .build()

        val signedRequest = original.newBuilder()
            .url(signedUrl)
            .build()

        return chain.proceed(signedRequest)
    }

    private fun hmacSha1(message: String, key: String): String {
        val mac = Mac.getInstance(HMAC_SHA1)
        mac.init(SecretKeySpec(key.toByteArray(Charsets.UTF_8), HMAC_SHA1))
        val bytes = mac.doFinal(message.toByteArray(Charsets.UTF_8))
        // PTV accepts either case; uppercase hex is the documented convention.
        return bytes.joinToString("") { "%02X".format(Locale.ROOT, it) }
    }

    private companion object {
        const val HMAC_SHA1 = "HmacSHA1"
    }
}
