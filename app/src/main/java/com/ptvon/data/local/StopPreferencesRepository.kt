package com.ptvon.data.local

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import com.ptvon.domain.model.PinnedStop
import com.ptvon.ui.theme.ThemeMode
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Persists the user's pinned stops (max [PinnedStop.MAX_PINS]) and the single
 * "current stop" that receives alerts. Backed by Preferences DataStore.
 */
@Singleton
class StopPreferencesRepository @Inject constructor(
    private val dataStore: DataStore<Preferences>,
    private val json: Json,
) {
    val pinnedStops: Flow<List<PinnedStop>> = dataStore.data.map { prefs ->
        prefs[KEY_PINS]?.let { raw ->
            runCatching { json.decodeFromString<List<PinnedStop>>(raw) }.getOrDefault(emptyList())
        } ?: emptyList()
    }

    /** The single tracked stop id, or null when tracking is off. */
    val currentStopId: Flow<Int?> = dataStore.data.map { prefs ->
        prefs[KEY_CURRENT].takeIf { it != NO_CURRENT }
    }

    /** Day/night theme preference; defaults to following the system. */
    val themeMode: Flow<ThemeMode> = dataStore.data.map { prefs ->
        prefs[KEY_THEME]?.let { runCatching { ThemeMode.valueOf(it) }.getOrNull() }
            ?: ThemeMode.SYSTEM
    }

    suspend fun setThemeMode(mode: ThemeMode) {
        dataStore.edit { it[KEY_THEME] = mode.name }
    }

    /** Whether the first-run onboarding has been completed. */
    val hasOnboarded: Flow<Boolean> = dataStore.data.map { it[KEY_ONBOARDED] ?: false }

    suspend fun setOnboarded() {
        dataStore.edit { it[KEY_ONBOARDED] = true }
    }

    suspend fun addPin(stop: PinnedStop): Boolean {
        val current = pinnedStops.first()
        if (current.any { it.stopId == stop.stopId }) return true
        if (current.size >= PinnedStop.MAX_PINS) return false
        writePins(current + stop)
        return true
    }

    suspend fun removePin(stopId: Int) {
        val current = pinnedStops.first()
        writePins(current.filterNot { it.stopId == stopId })
        if (currentStopId.first() == stopId) setCurrent(null)
    }

    /** Toggle [stopId] as the current tracked stop; selecting a new one replaces the old. */
    suspend fun toggleCurrent(stopId: Int) {
        val active = currentStopId.first()
        setCurrent(if (active == stopId) null else stopId)
    }

    suspend fun setCurrent(stopId: Int?) {
        dataStore.edit { it[KEY_CURRENT] = stopId ?: NO_CURRENT }
    }

    private suspend fun writePins(pins: List<PinnedStop>) {
        dataStore.edit { it[KEY_PINS] = json.encodeToString(pins) }
    }

    private companion object {
        val KEY_PINS = stringPreferencesKey("pinned_stops")
        val KEY_CURRENT = intPreferencesKey("current_stop_id")
        val KEY_THEME = stringPreferencesKey("theme_mode")
        val KEY_ONBOARDED = booleanPreferencesKey("has_onboarded")
        const val NO_CURRENT = -1
    }
}
