package com.ptvon.ui.onboarding

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsTransit
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun OnboardingScreen(
    onGetStarted: () -> Unit,
    onSkip: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 28.dp, vertical = 40.dp),
    ) {
        Spacer(Modifier.height(24.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Text("PTV", fontWeight = FontWeight.Black, fontSize = 44.sp, color = MaterialTheme.colorScheme.onBackground)
            Text("on", fontWeight = FontWeight.Black, fontSize = 44.sp, color = MaterialTheme.colorScheme.primary)
        }
        Spacer(Modifier.height(8.dp))
        Text(
            text = "Live Melbourne departures, the moment you open the app.",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        Spacer(Modifier.height(40.dp))

        FeatureRow(
            icon = Icons.Filled.PushPin,
            title = "Pin up to 4 stops",
            body = "Search the stops you use most. They're saved for every launch.",
        )
        FeatureRow(
            icon = Icons.Filled.NotificationsActive,
            title = "Track one stop for alerts",
            body = "Tap the bell to get 10 / 5 / 1-minute warnings and a live lock-screen countdown.",
        )
        FeatureRow(
            icon = Icons.Filled.DirectionsTransit,
            title = "Delays at a glance",
            body = "Service alerts and disruptions show right on each stop.",
        )
        FeatureRow(
            icon = Icons.Filled.WbSunny,
            title = "Weather & day/night",
            body = "Real-feel advice on what to wear, plus a daylight theme toggle.",
        )

        Spacer(Modifier.weight(1f))

        Button(
            onClick = onGetStarted,
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
            ),
        ) {
            Text("Add your stops", fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
        TextButton(
            onClick = onSkip,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Maybe later", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun FeatureRow(icon: ImageVector, title: String, body: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        }
        Spacer(Modifier.width(16.dp))
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
