package com.ptvon.ui.dashboard.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ptvon.domain.model.HourForecast
import com.ptvon.domain.model.WeatherCondition
import kotlin.math.cos
import kotlin.math.sin

// ---------------------------------------------------------------------------
// Current weather — small animated circular badge.
// ---------------------------------------------------------------------------

@Composable
fun CurrentWeatherBadge(condition: WeatherCondition, isDay: Boolean, modifier: Modifier = Modifier) {
    val anim = rememberInfiniteTransition(label = "badge")
    val bob by anim.animateFloat(0f, 1f, infiniteRepeatable(tween(2800), RepeatMode.Reverse), label = "bob")
    val fall by anim.animateFloat(0f, 1f, infiniteRepeatable(tween(1500, easing = LinearEasing)), label = "fall")
    val pulse by anim.animateFloat(0f, 1f, infiniteRepeatable(tween(2600), RepeatMode.Reverse), label = "pulse")

    Canvas(modifier = modifier.clip(CircleShape)) {
        drawSky(condition, isDay)
        val cx = size.width * 0.5f
        val cy = size.height * (0.46f + (bob - 0.5f) * 0.05f)
        val r = size.height * 0.22f
        val wet = condition in WET
        when {
            condition == WeatherCondition.CLEAR && isDay -> sun(Offset(cx, cy), r, pulse)
            condition == WeatherCondition.CLEAR -> moon(Offset(cx, cy), r)
            wet -> {
                cloud(Offset(cx, cy - r * 0.2f), r * 0.9f, Color(0xFFE7EEF7))
                if (condition == WeatherCondition.SNOW) snow(fall) else drops(fall)
            }
            else -> {
                if (isDay) sun(Offset(cx + r * 0.5f, cy - r * 0.3f), r * 0.7f, pulse) else moon(Offset(cx + r * 0.5f, cy - r * 0.3f), r * 0.7f)
                cloud(Offset(cx, cy + r * 0.2f), r * 0.85f, Color(0xFFEFF4FA))
            }
        }
    }
}

// ---------------------------------------------------------------------------
// 6-hour forecast strip.
// ---------------------------------------------------------------------------

@Composable
fun HourlyForecastStrip(forecast: List<HourForecast>, modifier: Modifier = Modifier) {
    val anim = rememberInfiniteTransition(label = "fc")
    val fall by anim.animateFloat(0f, 1f, infiniteRepeatable(tween(1600, easing = LinearEasing)), label = "fcfall")
    val pulse by anim.animateFloat(0f, 1f, infiniteRepeatable(tween(2600), RepeatMode.Reverse), label = "fcpulse")

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        forecast.forEach { h ->
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(h.label, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                MiniWeatherGlyph(
                    condition = h.condition,
                    isDay = h.isDay,
                    fall = fall,
                    pulse = pulse,
                    modifier = Modifier.size(28.dp).padding(vertical = 5.dp),
                )
                Text("${h.tempC}°", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
            }
        }
    }
}

@Composable
private fun MiniWeatherGlyph(condition: WeatherCondition, isDay: Boolean, fall: Float, pulse: Float, modifier: Modifier) {
    Canvas(modifier = modifier) {
        val cx = size.width * 0.5f
        val cy = size.height * 0.42f
        val r = size.minDimension * 0.26f
        val wet = condition in WET
        when {
            condition == WeatherCondition.CLEAR && isDay -> sun(Offset(cx, cy), r, pulse)
            condition == WeatherCondition.CLEAR -> moon(Offset(cx, cy), r)
            wet -> {
                cloud(Offset(cx, cy), r, Color(0xFFC9D6E8))
                if (condition == WeatherCondition.SNOW) snow(fall) else drops(fall)
            }
            else -> cloud(Offset(cx, cy), r, Color(0xFFC9D6E8))
        }
    }
}

// ---------------------------------------------------------------------------
// Shared drawing.
// ---------------------------------------------------------------------------

private val WET = setOf(
    WeatherCondition.RAIN, WeatherCondition.SHOWERS, WeatherCondition.STORM, WeatherCondition.SNOW,
)

private fun DrawScope.drawSky(c: WeatherCondition, day: Boolean) {
    val (top, bottom) = when {
        !day && c == WeatherCondition.CLEAR -> Color(0xFF12224A) to Color(0xFF35508A)
        !day -> Color(0xFF1A2440) to Color(0xFF33446B)
        c == WeatherCondition.CLEAR -> Color(0xFFFF9A45) to Color(0xFFFFC65A)
        c == WeatherCondition.STORM -> Color(0xFF3A435C) to Color(0xFF5A6688)
        c in WET -> Color(0xFF4E6A88) to Color(0xFF7E9AB6)
        else -> Color(0xFF5E83B4) to Color(0xFF9FC0DC)
    }
    drawRect(Brush.verticalGradient(listOf(top, bottom)))
}

private fun DrawScope.sun(c: Offset, r: Float, pulse: Float) {
    rotate(pulse * 14f, c) {
        for (i in 0 until 8) {
            val a = (i * 45f) * (Math.PI.toFloat() / 180f)
            drawLine(
                Color(0xCCFFD27A),
                Offset(c.x + cos(a) * r * 1.35f, c.y + sin(a) * r * 1.35f),
                Offset(c.x + cos(a) * r * 1.7f, c.y + sin(a) * r * 1.7f),
                strokeWidth = r * 0.18f, cap = StrokeCap.Round,
            )
        }
    }
    drawCircle(Color(0xFFFFB23E), r, c)
    face(c, r, Color(0xFF0B1530))
}

private fun DrawScope.moon(c: Offset, r: Float) {
    drawCircle(Color(0xFFF3ECCF), r, c)
    drawCircle(Color(0xFF24304F), r * 0.92f, Offset(c.x + r * 0.5f, c.y - r * 0.2f))
    face(Offset(c.x - r * 0.12f, c.y), r * 0.85f, Color(0xFF24304F))
}

private fun DrawScope.face(c: Offset, r: Float, ink: Color) {
    val sw = r * 0.12f
    val eyeW = r * 0.34f
    drawArc(ink, 180f, 180f, false, Offset(c.x - r * 0.46f - eyeW / 2, c.y - r * 0.1f), Size(eyeW, eyeW * 0.6f), style = Stroke(sw, cap = StrokeCap.Round))
    drawArc(ink, 180f, 180f, false, Offset(c.x + r * 0.46f - eyeW / 2, c.y - r * 0.1f), Size(eyeW, eyeW * 0.6f), style = Stroke(sw, cap = StrokeCap.Round))
    val mW = r * 0.7f
    drawArc(ink, 0f, 180f, false, Offset(c.x - mW / 2, c.y + r * 0.1f), Size(mW, mW * 0.5f), style = Stroke(sw, cap = StrokeCap.Round))
}

private fun DrawScope.cloud(center: Offset, r: Float, color: Color) {
    drawCircle(color, r, center)
    drawCircle(color, r * 0.76f, Offset(center.x - r * 1.0f, center.y + r * 0.2f))
    drawCircle(color, r * 0.84f, Offset(center.x + r * 1.0f, center.y + r * 0.16f))
    drawRect(color, topLeft = Offset(center.x - r * 1.55f, center.y), size = Size(r * 3.1f, r * 0.85f))
}

private fun DrawScope.drops(fall: Float) {
    val w = size.width
    val h = size.height
    for (i in 0 until 3) {
        val x = w * (0.3f + i * 0.2f)
        val p = (fall + i * 0.33f) % 1f
        val y = h * 0.55f + p * h * 0.35f
        drawLine(Color(0xCC7FC0EC), Offset(x, y), Offset(x, y + h * 0.14f), strokeWidth = h * 0.05f, cap = StrokeCap.Round)
    }
}

private fun DrawScope.snow(fall: Float) {
    val w = size.width
    val h = size.height
    for (i in 0 until 3) {
        val x = w * (0.3f + i * 0.2f) + sin((fall * 6.28f) + i) * w * 0.04f
        val p = (fall + i * 0.33f) % 1f
        val y = h * 0.55f + p * h * 0.35f
        drawCircle(Color(0xFFFFFFFF), h * 0.05f, Offset(x, y))
    }
}
