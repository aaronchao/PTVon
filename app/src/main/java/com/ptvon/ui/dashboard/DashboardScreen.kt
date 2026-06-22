package com.ptvon.ui.dashboard

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.ptvon.R
import com.ptvon.ui.dashboard.components.StationDepartureCard
import com.ptvon.ui.dashboard.components.WeatherAdviceBar

@Composable
fun DashboardScreen(
    onAddStops: () -> Unit,
    isDark: Boolean,
    onToggleTheme: () -> Unit,
    viewModel: DashboardViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Scaffold(containerColor = MaterialTheme.colorScheme.background) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            item {
                Header(
                    isDemo = state.isDemoMode,
                    canAdd = state.canAddMore,
                    onAddStops = onAddStops,
                    isDark = isDark,
                    onToggleTheme = onToggleTheme,
                )
            }

            state.weather?.let { advice ->
                item(key = "weather") {
                    Box(Modifier.animateItem()) {
                        EnterAnimated(index = 0) { WeatherAdviceBar(advice) }
                    }
                }
            }

            itemsIndexed(state.boards, key = { _, b -> b.stopId }) { index, board ->
                val removable = state.pins.any { it.stopId == board.stopId }
                Box(Modifier.animateItem()) {
                    EnterAnimated(index = index + 1) {
                        val card: @Composable () -> Unit = {
                            StationDepartureCard(
                                board = board,
                                nowMillis = state.nowMillis,
                                isTracked = state.currentStopId == board.stopId,
                                onToggleTrack = { viewModel.toggleTrack(board.stopId) },
                            )
                        }
                        if (removable) {
                            SwipeableStopCard(onRemove = { viewModel.unpin(board.stopId) }, content = card)
                        } else {
                            card()
                        }
                    }
                }
            }

            if (!state.isLoading && !state.hasPins) {
                item { EmptyState(onAddStops = onAddStops) }
            }
        }
    }
}

@Composable
private fun Header(
    isDemo: Boolean,
    canAdd: Boolean,
    onAddStops: () -> Unit,
    isDark: Boolean,
    onToggleTheme: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Melbourne · live departures",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Row(verticalAlignment = Alignment.Bottom) {
                Image(
                    painter = painterResource(R.drawable.ic_tram_mark),
                    contentDescription = null,
                    modifier = Modifier
                        .padding(end = 8.dp, bottom = 2.dp)
                        .size(30.dp),
                )
                Text("PTV", fontWeight = FontWeight.ExtraBold, fontSize = 30.sp, color = MaterialTheme.colorScheme.onBackground)
                Text("on", fontWeight = FontWeight.ExtraBold, fontSize = 30.sp, color = MaterialTheme.colorScheme.primary)
            }
            if (isDemo) {
                Text(
                    text = "Demo · add PTV devid for live data",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 2.dp),
                )
            }
        }
        IconButton(onClick = onToggleTheme) {
            Icon(
                imageVector = if (isDark) Icons.Filled.LightMode else Icons.Filled.DarkMode,
                contentDescription = if (isDark) "Switch to day mode" else "Switch to night mode",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (canAdd) {
            Button(
                onClick = onAddStops,
                shape = RoundedCornerShape(50),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary,
                ),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 10.dp),
            ) {
                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.height(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Add", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun EmptyState(onAddStops: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "No stops pinned yet",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = "Pin up to 4 stops you use often. Double-tap or tap the bell on a stop to get departure alerts.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 24.dp),
        )
        Spacer(Modifier.height(18.dp))
        Button(
            onClick = onAddStops,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
            ),
        ) {
            Icon(Icons.Filled.Add, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text("Add stops", fontWeight = FontWeight.Bold)
        }
    }
}

/** Swipe a pinned board left to remove it. */
@Composable
private fun SwipeableStopCard(onRemove: () -> Unit, content: @Composable () -> Unit) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { value ->
            if (value == SwipeToDismissBoxValue.EndToStart) {
                onRemove()
                true
            } else {
                false
            }
        },
    )
    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        enableDismissFromEndToStart = true,
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(110.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(MaterialTheme.colorScheme.errorContainer)
                    .padding(end = 24.dp),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Icon(
                    imageVector = Icons.Filled.Delete,
                    contentDescription = "Remove stop",
                    tint = MaterialTheme.colorScheme.onErrorContainer,
                )
            }
        },
        content = { content() },
    )
}

/** Staggered fade + slide-in so boards arrive gracefully. */
@Composable
private fun EnterAnimated(index: Int, content: @Composable () -> Unit) {
    val visibleState = remember {
        MutableTransitionState(false).apply { targetState = true }
    }
    AnimatedVisibility(
        visibleState = visibleState,
        enter = fadeIn(tween(durationMillis = 350, delayMillis = index * 80)) +
            slideInVertically(
                animationSpec = tween(durationMillis = 350, delayMillis = index * 80),
                initialOffsetY = { it / 4 },
            ),
    ) {
        content()
    }
}
