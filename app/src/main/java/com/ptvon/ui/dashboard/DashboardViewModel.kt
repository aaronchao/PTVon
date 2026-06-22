package com.ptvon.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptvon.core.notifications.AlertScheduler
import com.ptvon.core.notifications.TrackingController
import com.ptvon.core.time.TimeSource
import com.ptvon.data.local.StopPreferencesRepository
import com.ptvon.data.repository.DepartureRepository
import com.ptvon.data.repository.WeatherRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val departureRepository: DepartureRepository,
    private val weatherRepository: WeatherRepository,
    private val stopPreferences: StopPreferencesRepository,
    private val alertScheduler: AlertScheduler,
    private val trackingController: TrackingController,
    private val timeSource: TimeSource,
) : ViewModel() {

    private val _state = MutableStateFlow(
        DashboardUiState(
            isDemoMode = departureRepository.isDemoMode,
            nowMillis = timeSource.nowMillis(),
        )
    )
    val state = _state.asStateFlow()

    init {
        observePins()
        observeCurrentStop()
        loadWeather()
        startClock()
    }

    /** Toggle the tracked "current stop" (double-tap on a card, or the bell). */
    fun toggleTrack(stopId: Int) {
        viewModelScope.launch { stopPreferences.toggleCurrent(stopId) }
    }

    fun unpin(stopId: Int) {
        viewModelScope.launch { stopPreferences.removePin(stopId) }
    }

    fun refresh() {
        viewModelScope.launch {
            val boards = departureRepository.loadBoards(_state.value.pins)
            _state.update { it.copy(boards = boards) }
            rescheduleAlerts()
        }
    }

    private fun observePins() {
        viewModelScope.launch {
            stopPreferences.pinnedStops.collectLatest { pins ->
                _state.update { it.copy(pins = pins) }
                val boards = departureRepository.loadBoards(pins)
                _state.update { it.copy(boards = boards, isLoading = false) }
                rescheduleAlerts()
            }
        }
    }

    private fun observeCurrentStop() {
        viewModelScope.launch {
            stopPreferences.currentStopId.collectLatest { id ->
                _state.update { it.copy(currentStopId = id) }
                rescheduleAlerts()
            }
        }
    }

    /** Keep alarms AND the live lock-screen banner in sync with the tracked stop. */
    private fun rescheduleAlerts() {
        val currentId = _state.value.currentStopId
        val board = _state.value.boards.firstOrNull { it.stopId == currentId }
        if (board != null) {
            alertScheduler.scheduleFor(board)
            trackingController.start(board)
        } else {
            alertScheduler.cancelAll()
            trackingController.stop()
        }
    }

    private fun loadWeather() {
        viewModelScope.launch {
            val advice = weatherRepository.adviceFor(MELBOURNE_LAT, MELBOURNE_LON)
            _state.update { it.copy(weather = advice) }
        }
    }

    private fun startClock() {
        viewModelScope.launch {
            while (true) {
                _state.update { it.copy(nowMillis = timeSource.nowMillis()) }
                delay(1_000)
            }
        }
    }

    private companion object {
        const val MELBOURNE_LAT = -37.8183
        const val MELBOURNE_LON = 144.9671
    }
}
