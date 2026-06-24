package com.ptvon.ui.dashboard.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.draw.drawBehind
import androidx.compose.animation.core.LinearEasing
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ptvon.domain.model.Departure
import com.ptvon.domain.model.Disruption
import com.ptvon.domain.model.StationBoard

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun StationDepartureCard(
    board: StationBoard,
    nowMillis: Long,
    isTracked: Boolean,
    onToggleTrack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    PtvCard(
        modifier = modifier.combinedClickable(
            onClick = {},
            onDoubleClick = onToggleTrack, // power-user shortcut
        ),
        highlighted = isTracked,
    ) {
        Column(modifier = Modifier.padding(vertical = 12.dp)) {
            // Station header + track bell
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 18.dp, end = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier = Modifier
                        .size(width = 4.dp, height = 26.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(Color(board.routeType.brandColor)),
                )
                Spacer(Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = board.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        text = listOfNotNull(
                            board.suburb,
                            if (isTracked) "Alerts on" else null,
                        ).joinToString(" · "),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isTracked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                IconButton(onClick = onToggleTrack) {
                    Icon(
                        imageVector = if (isTracked) Icons.Filled.NotificationsActive
                        else Icons.Outlined.Notifications,
                        contentDescription = if (isTracked) "Stop alerts" else "Track this stop",
                        tint = if (isTracked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            if (board.disruptions.isNotEmpty()) {
                Spacer(Modifier.height(12.dp))
                DisruptionStrip(board.disruptions)
            }

            Spacer(Modifier.height(8.dp))

            if (board.departures.isEmpty()) {
                Text(
                    text = "No departures",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp),
                )
            } else {
                board.departures.forEachIndexed { i, departure ->
                    if (i > 0) {
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 18.dp, end = 18.dp),
                            thickness = 1.dp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.06f),
                        )
                    }
                    DepartureRow(departure, nowMillis)
                }
            }
        }
    }
}

@Composable
private fun DepartureRow(departure: Departure, nowMillis: Long) {
    val minutes = departure.minutesUntil(nowMillis)
    val due = departure.isDue(nowMillis)

    // Gentle glow on the countdown when a service is about to leave.
    val imminent = !due && minutes in 1..2
    val pulse = rememberInfiniteTransition(label = "imminent")
    val pulseAlpha by pulse.animateFloat(
        initialValue = 1f,
        targetValue = 0.5f,
        animationSpec = infiniteRepeatable(tween(750), RepeatMode.Reverse),
        label = "pulseAlpha",
    )
    val numberAlpha = if (imminent) pulseAlpha else 1f

    Box(modifier = Modifier.fillMaxWidth()) {
    if (departure.isExpress) {
        ExpressShimmer(Color(departure.routeType.brandColor), Modifier.matchParentSize())
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Fixed width so destinations + live dots line up across every row.
        Box(
            modifier = Modifier
                .width(84.dp)
                .height(30.dp)
                .clip(RoundedCornerShape(20.dp))
                .background(Color(departure.routeType.brandColor))
                .padding(horizontal = 8.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = departure.label.ifBlank { departure.routeType.displayName },
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        Spacer(Modifier.width(14.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = departure.destination,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (departure.isExpress) {
                    Spacer(Modifier.width(6.dp))
                    ExpressTag(Color(departure.routeType.brandColor))
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (departure.isLive) {
                    LiveDot()
                    Spacer(Modifier.width(6.dp))
                }
                Text(
                    text = if (departure.isLive) "Live"
                    else "Scheduled" + (departure.platform?.let { " · Plat $it" } ?: ""),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Spacer(Modifier.width(12.dp))

        AnimatedContent(
            targetState = if (due) "NOW" else minutes.toString(),
            transitionSpec = {
                (slideInVertically { it / 2 } + fadeIn(tween(250)))
                    .togetherWith(slideOutVertically { -it / 2 } + fadeOut(tween(250)))
            },
            label = "countdown",
        ) { value ->
            val isNow = value == "NOW"
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = value,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = if (isNow) 24.sp else 38.sp,
                    color = (if (isNow) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)
                        .copy(alpha = numberAlpha),
                )
                if (!isNow) {
                    Text(
                        text = " min",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 6.dp),
                    )
                }
            }
        }
    }
    }
}

/** Compact, expandable delays/alerts strip. Collapsed shows a one-line summary. */
@Composable
private fun DisruptionStrip(disruptions: List<Disruption>) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .padding(horizontal = 18.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f))
            .clickable(enabled = disruptions.isNotEmpty()) { expanded = !expanded }
            .padding(horizontal = 12.dp, vertical = 10.dp)
            .animateContentSize(),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Filled.WarningAmber,
                contentDescription = "Service alert",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp),
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = summary(disruptions),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.SemiBold,
                maxLines = if (expanded) Int.MAX_VALUE else 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            Icon(
                imageVector = if (expanded) Icons.Filled.KeyboardArrowDown
                else Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = if (expanded) "Collapse" else "Expand",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp),
            )
        }

        if (expanded) {
            disruptions.forEach { d ->
                Spacer(Modifier.height(8.dp))
                Text(
                    text = (if (d.isPlanned) "Planned · " else "") + d.title,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(start = 26.dp),
                )
                d.description?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = 26.dp, top = 2.dp),
                    )
                }
            }
        }
    }
}

private fun summary(disruptions: List<Disruption>): String = when (disruptions.size) {
    1 -> disruptions.first().title
    else -> "${disruptions.size} service alerts — ${disruptions.first().title}"
}

/** Animated "Express ›››" tag — sliding chevrons make the service feel fast. */
@Composable
private fun ExpressTag(color: Color) {
    val t = rememberInfiniteTransition(label = "exptag")
    val phase by t.animateFloat(
        initialValue = 0f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(tween(900, easing = LinearEasing), RepeatMode.Restart),
        label = "phase",
    )
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(color.copy(alpha = 0.16f))
            .padding(horizontal = 6.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("Express", color = color, fontWeight = FontWeight.Bold, fontSize = 10.sp)
        Spacer(Modifier.width(3.dp))
        Row {
            repeat(3) { i ->
                val a = if (phase.toInt() % 3 == i) 1f else 0.3f
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = color.copy(alpha = a),
                    modifier = Modifier
                        .size(11.dp)
                        .offset(x = (-4 * i).dp),
                )
            }
        }
    }
}

/** A bright band that sweeps across an express row. */
@Composable
private fun ExpressShimmer(color: Color, modifier: Modifier = Modifier) {
    val t = rememberInfiniteTransition(label = "expshim")
    val x by t.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1700, easing = LinearEasing), RepeatMode.Restart),
        label = "x",
    )
    Box(
        modifier.drawBehind {
            val w = size.width
            val band = w * 0.5f
            val startX = -band + x * (w + band)
            drawRect(
                brush = Brush.horizontalGradient(
                    0f to Color.Transparent,
                    0.5f to color.copy(alpha = 0.18f),
                    1f to Color.Transparent,
                    startX = startX,
                    endX = startX + band,
                ),
            )
        },
    )
}

@Composable
private fun LiveDot() {
    val transition = rememberInfiniteTransition(label = "live")
    val alpha by transition.animateFloat(
        initialValue = 1f,
        targetValue = 0.25f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "liveAlpha",
    )
    Box(
        modifier = Modifier
            .size(7.dp)
            .alpha(alpha)
            .clip(RoundedCornerShape(50))
            .background(Color(0xFF49D17E)),
    )
}
