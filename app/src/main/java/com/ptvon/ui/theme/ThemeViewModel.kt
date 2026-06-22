package com.ptvon.ui.theme

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptvon.data.local.StopPreferencesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ThemeViewModel @Inject constructor(
    private val stopPreferences: StopPreferencesRepository,
) : ViewModel() {

    val themeMode = stopPreferences.themeMode.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ThemeMode.SYSTEM,
    )

    /** Flip to the explicit opposite of whatever is currently showing. */
    fun toggle(currentlyDark: Boolean) {
        viewModelScope.launch {
            stopPreferences.setThemeMode(if (currentlyDark) ThemeMode.LIGHT else ThemeMode.DARK)
        }
    }
}
