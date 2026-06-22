package com.ptvon.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptvon.data.local.StopPreferencesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val stopPreferences: StopPreferencesRepository,
) : ViewModel() {

    /** null = still loading the flag; true/false once known (drives start destination). */
    val hasOnboarded: StateFlow<Boolean?> = stopPreferences.hasOnboarded
        .map { it as Boolean? }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = null,
        )

    fun complete() {
        viewModelScope.launch { stopPreferences.setOnboarded() }
    }
}
