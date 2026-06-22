package com.ptvon.ui.dashboard.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ptvon.domain.model.WeatherAdvice

@Composable
fun WeatherAdviceBar(advice: WeatherAdvice, modifier: Modifier = Modifier) {
    PtvCard(modifier = modifier) {
        // Current conditions — compact row.
        Row(
            modifier = Modifier.padding(start = 14.dp, end = 16.dp, top = 14.dp, bottom = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CurrentWeatherBadge(
                condition = advice.condition,
                isDay = advice.isDay,
                modifier = Modifier.size(52.dp),
            )
            Column(modifier = Modifier.padding(start = 14.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = "${advice.actualC}°",
                        fontSize = 26.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                    Text(
                        text = "  feels ${advice.realFeelC}°",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 4.dp),
                    )
                }
                Text(
                    text = advice.headline,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        if (advice.forecast.isNotEmpty()) {
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 14.dp),
                thickness = 1.dp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.07f),
            )
            Spacer(Modifier.size(10.dp))
            HourlyForecastStrip(
                forecast = advice.forecast,
                modifier = Modifier.padding(horizontal = 12.dp),
            )
            Spacer(Modifier.size(14.dp))
        }
    }
}
