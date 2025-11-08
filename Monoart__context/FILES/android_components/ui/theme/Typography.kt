package com.digitalreality.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextTransform
import androidx.compose.ui.unit.sp
import com.digitalreality.R

// IBM Plex Mono font family
val IBMPlexMono = FontFamily(
    Font(R.font.ibm_plex_mono_regular, FontWeight.Normal),
    Font(R.font.ibm_plex_mono_medium, FontWeight.Medium),
    Font(R.font.ibm_plex_mono_semibold, FontWeight.SemiBold)
)

// Стили текста из StylesToken.json
object AppTypography {
    val body1 = TextStyle(
        fontFamily = IBMPlexMono,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        letterSpacing = 0.sp
    )
    
    val body2 = TextStyle(
        fontFamily = IBMPlexMono,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        letterSpacing = 0.sp
    )
    
    val head1 = TextStyle(
        fontFamily = IBMPlexMono,
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        letterSpacing = 0.sp,
        lineHeight = 18.sp
    )
}

// Material 3 Typography
val AppTypographyMaterial = Typography(
    bodyMedium = AppTypography.body1,
    bodyLarge = AppTypography.body2,
    headlineSmall = AppTypography.head1
)
