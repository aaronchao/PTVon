package com.ptvon.ui.dashboard.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Friendly Headspace-style panel: a flat, softly-rounded surface that gets an
 * electric-blue outline when highlighted (the tracked stop).
 */
@Composable
fun PtvCard(
    modifier: Modifier = Modifier,
    highlighted: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = if (highlighted) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
    ) {
        Column(modifier = Modifier.fillMaxWidth(), content = content)
    }
}
