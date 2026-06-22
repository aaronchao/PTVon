package com.ptvon

import android.app.Application
import com.ptvon.core.notifications.NotificationChannels
import dagger.hilt.android.HiltAndroidApp

/**
 * Application entry point. `@HiltAndroidApp` bootstraps the Hilt dependency graph
 * (SingletonComponent) for the whole app.
 */
@HiltAndroidApp
class PtvOnApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NotificationChannels.ensureChannels(this)
    }
}
