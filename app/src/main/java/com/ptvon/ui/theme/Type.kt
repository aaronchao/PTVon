package com.ptvon.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.ptvon.R

// Nunito — a rounded, friendly geometric sans (Headspace-style warmth).
// Variable font; weights selected via FontVariation.
@OptIn(ExperimentalTextApi::class)
private fun nunito(weight: Int) = Font(
    R.font.nunito_variable,
    weight = FontWeight(weight),
    variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
)

val Nunito = FontFamily(
    nunito(400),
    nunito(500),
    nunito(600),
    nunito(700),
    nunito(800),
)

val Typography = Typography(
    displaySmall = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.ExtraBold, fontSize = 34.sp),
    headlineLarge = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.ExtraBold, fontSize = 30.sp),
    headlineMedium = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.ExtraBold, fontSize = 26.sp),
    titleLarge = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.Bold, fontSize = 22.sp),
    titleMedium = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.Bold, fontSize = 17.sp),
    bodyLarge = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 22.sp),
    bodyMedium = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.Bold, fontSize = 15.sp),
    labelMedium = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.SemiBold, fontSize = 13.sp),
    labelSmall = TextStyle(fontFamily = Nunito, fontWeight = FontWeight.SemiBold, fontSize = 12.sp),
)
