package com.digitalreality.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = AppColors.White,
    onPrimary = AppColors.Black,
    secondary = AppColors.MainGrey,
    onSecondary = AppColors.White,
    tertiary = AppColors.White20,
    onTertiary = AppColors.White,
    background = AppColors.BackgroundDark,
    onBackground = AppColors.White,
    surface = AppColors.MainGrey,
    onSurface = AppColors.White,
    surfaceVariant = AppColors.BackgroundDark,
    onSurfaceVariant = AppColors.White40,
    outline = AppColors.White20,
    outlineVariant = AppColors.White20
)

@Composable
fun DigitalRealityTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // Приложение всегда использует темную тему
    val colorScheme = DarkColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypographyMaterial,
        content = content
    )
}
