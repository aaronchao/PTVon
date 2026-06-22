package com.ptvon.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

/** User theme preference. SYSTEM follows the device; LIGHT/DAY and DARK/NIGHT are explicit. */
enum class ThemeMode { SYSTEM, LIGHT, DARK }

private val PtvonDarkScheme = darkColorScheme(
    primary = ElectricBlue,
    onPrimary = Cloud,
    background = Navy0,
    onBackground = Cloud,
    surface = Navy1,
    onSurface = Cloud,
    surfaceVariant = Navy2,
    onSurfaceVariant = Mist,
    outline = NavyLine,
)

private val PtvonLightScheme = lightColorScheme(
    primary = ElectricBlueDim,
    onPrimary = Cloud,
    background = Sky0,
    onBackground = Ink,
    surface = Sky1,
    onSurface = Ink,
    surfaceVariant = Sky2,
    onSurfaceVariant = InkMuted,
    outline = SkyLine,
)

// Big, friendly corner radii — Headspace roundness.
private val PtvonShapes = Shapes(
    extraSmall = RoundedCornerShape(10.dp),
    small = RoundedCornerShape(14.dp),
    medium = RoundedCornerShape(20.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

@Composable
fun PtvonTheme(
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    content: @Composable () -> Unit,
) {
    val darkTheme = when (themeMode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }
    val colorScheme = if (darkTheme) PtvonDarkScheme else PtvonLightScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = PtvonShapes,
    ) {
        // Make Nunito the default for every Text (incl. ones with custom sizes).
        CompositionLocalProvider(
            LocalTextStyle provides LocalTextStyle.current.copy(fontFamily = Nunito),
            content = content,
        )
    }
}
