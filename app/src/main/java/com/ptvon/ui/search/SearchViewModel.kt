package com.ptvon.ui.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptvon.data.local.StopPreferencesRepository
import com.ptvon.data.repository.StopSearchRepository
import com.ptvon.domain.model.PinnedStop
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SearchUiState(
    val query: String = "",
    val isSearching: Boolean = false,
    val results: List<PinnedStop> = emptyList(),
    val pinnedIds: Set<Int> = emptySet(),
    val pinnedCount: Int = 0,
    val atCapacity: Boolean = false,
)

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val searchRepository: StopSearchRepository,
    private val stopPreferences: StopPreferencesRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(SearchUiState())
    val state = _state.asStateFlow()

    private var searchJob: Job? = null

    init {
        viewModelScope.launch {
            stopPreferences.pinnedStops.collect { pins ->
                _state.update {
                    it.copy(
                        pinnedIds = pins.map { p -> p.stopId }.toSet(),
                        pinnedCount = pins.size,
                        atCapacity = pins.size >= PinnedStop.MAX_PINS,
                    )
                }
            }
        }
    }

    fun onQueryChange(query: String) {
        _state.update { it.copy(query = query) }
        searchJob?.cancel()
        if (query.isBlank()) {
            _state.update { it.copy(results = emptyList(), isSearching = false) }
            return
        }
        searchJob = viewModelScope.launch {
            delay(300) // debounce
            _state.update { it.copy(isSearching = true) }
            val results = searchRepository.search(query)
            _state.update { it.copy(results = results, isSearching = false) }
        }
    }

    fun togglePin(stop: PinnedStop) {
        viewModelScope.launch {
            if (_state.value.pinnedIds.contains(stop.stopId)) {
                stopPreferences.removePin(stop.stopId)
            } else {
                stopPreferences.addPin(stop)
            }
        }
    }
}
