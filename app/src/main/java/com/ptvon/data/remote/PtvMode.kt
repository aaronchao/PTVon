package com.ptvon.data.remote

import com.ptvon.BuildConfig

/** Single source of truth for how the app reaches PTV: proxy, direct key, or demo. */
object PtvMode {
    val usingProxy: Boolean get() = BuildConfig.PTV_PROXY_URL.isNotBlank()
    val hasDirectKey: Boolean
        get() = BuildConfig.PTV_DEV_ID.isNotBlank() && BuildConfig.PTV_API_KEY.isNotBlank()

    /** Demo mode (sample data) only when there's neither a proxy nor direct credentials. */
    val isDemo: Boolean get() = !usingProxy && !hasDirectKey
}
