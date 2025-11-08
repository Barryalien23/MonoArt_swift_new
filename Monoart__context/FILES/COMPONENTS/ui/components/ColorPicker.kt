package com.digitalreality.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import com.digitalreality.data.models.ColorPickerMode
import com.digitalreality.data.models.ColorState
import com.digitalreality.data.models.SymbolPaint
import com.digitalreality.ui.theme.*

/**
 * Экран выбора цветов
 */
@Composable
fun ColorPickerScreen(
    colorState: ColorState,
    selectedMode: ColorPickerMode?,
    onModeSelected: (ColorPickerMode) -> Unit,
    onBackgroundColorChanged: (Color) -> Unit,
    onSymbolColorChanged: (Color) -> Unit,
    onGradientChanged: (Color, Color) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var color1 by remember { mutableStateOf(Color.White) }
    var color2 by remember { mutableStateOf(Color.White) }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .padding(Spacing.l),
        verticalArrangement = Arrangement.spacedBy(Spacing.l)
    ) {
        // Заголовок с кнопкой назад
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "ВЫБЕРИТЕ ЦВЕТА",
                style = AppTypography.head1,
                color = AppColors.White
            )
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_arrow_back),
                    contentDescription = "Back",
                    tint = AppColors.White
                )
            }
        }
        
        // Табы выбора режима
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.s)
        ) {
            ColorModeTab(
                title = "BG COLOR",
                isSelected = selectedMode == ColorPickerMode.BACKGROUND,
                onClick = { onModeSelected(ColorPickerMode.BACKGROUND) },
                modifier = Modifier.weight(1f)
            )
            ColorModeTab(
                title = "COLOR #1",
                isSelected = selectedMode == ColorPickerMode.COLOR_1,
                isEnabled = colorState.symbols !is SymbolPaint.Gradient,
                onClick = { onModeSelected(ColorPickerMode.COLOR_1) },
                modifier = Modifier.weight(1f)
            )
            ColorModeTab(
                title = "COLOR #2",
                isSelected = selectedMode == ColorPickerMode.COLOR_2,
                isEnabled = colorState.symbols !is SymbolPaint.Gradient,
                onClick = { onModeSelected(ColorPickerMode.COLOR_2) },
                modifier = Modifier.weight(1f)
            )
            ColorModeTab(
                title = "GRADIENT",
                isSelected = selectedMode == ColorPickerMode.GRADIENT,
                onClick = { onModeSelected(ColorPickerMode.GRADIENT) },
                modifier = Modifier.weight(1f)
            )
        }
        
        // Цветовой спектр и настройки
        selectedMode?.let { mode ->
            when (mode) {
                ColorPickerMode.BACKGROUND -> {
                    ColorSelector(
                        initialColor = colorState.background,
                        onColorChanged = onBackgroundColorChanged
                    )
                }
                ColorPickerMode.COLOR_1 -> {
                    ColorSelector(
                        initialColor = color1,
                        onColorChanged = { 
                            color1 = it
                            onSymbolColorChanged(it)
                        }
                    )
                }
                ColorPickerMode.COLOR_2 -> {
                    ColorSelector(
                        initialColor = color2,
                        onColorChanged = { 
                            color2 = it
                            onSymbolColorChanged(it)
                        }
                    )
                }
                ColorPickerMode.GRADIENT -> {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(Spacing.l)
                    ) {
                        Text(
                            text = "ПЕРВЫЙ ЦВЕТ",
                            style = AppTypography.body2,
                            color = AppColors.White
                        )
                        ColorSelector(
                            initialColor = color1,
                            onColorChanged = { 
                                color1 = it
                                onGradientChanged(color1, color2)
                            }
                        )
                        Text(
                            text = "ВТОРОЙ ЦВЕТ",
                            style = AppTypography.body2,
                            color = AppColors.White
                        )
                        ColorSelector(
                            initialColor = color2,
                            onColorChanged = { 
                                color2 = it
                                onGradientChanged(color1, color2)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ColorModeTab(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true
) {
    Box(
        modifier = modifier
            .height(48.dp)
            .clip(RoundedCornerShape(Roundings.m))
            .background(
                if (isSelected) AppColors.White20 else AppColors.MainGrey
            )
            .clickable(enabled = isEnabled) { onClick() }
            .padding(Spacing.m),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            style = AppTypography.body1,
            color = if (isEnabled) AppColors.White else AppColors.White40
        )
    }
}

@Composable
private fun ColorSelector(
    initialColor: Color,
    onColorChanged: (Color) -> Unit,
    modifier: Modifier = Modifier
) {
    var red by remember { mutableStateOf(initialColor.red) }
    var green by remember { mutableStateOf(initialColor.green) }
    var blue by remember { mutableStateOf(initialColor.blue) }
    var alpha by remember { mutableStateOf(initialColor.alpha) }
    
    val currentColor = Color(red, green, blue, alpha)
    
    LaunchedEffect(currentColor) {
        onColorChanged(currentColor)
    }
    
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.l)
    ) {
        // Превью цвета
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(60.dp)
                .clip(RoundedCornerShape(Roundings.m))
                .background(currentColor)
                .border(
                    1.dp,
                    AppColors.White20,
                    RoundedCornerShape(Roundings.m)
                )
        )
        
        // Слайдеры RGB
        ColorSlider("R", red) { red = it }
        ColorSlider("G", green) { green = it }
        ColorSlider("B", blue) { blue = it }
        ColorSlider("A", alpha) { alpha = it }
    }
}

@Composable
private fun ColorSlider(
    label: String,
    value: Float,
    onValueChange: (Float) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.m),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = AppTypography.body2,
            color = AppColors.White,
            modifier = Modifier.width(24.dp)
        )
        
        Slider(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.weight(1f),
            colors = SliderDefaults.colors(
                thumbColor = AppColors.White,
                activeTrackColor = AppColors.White,
                inactiveTrackColor = AppColors.White20
            )
        )
        
        Text(
            text = "${(value * 255).toInt()}",
            style = AppTypography.body2,
            color = AppColors.White,
            modifier = Modifier.width(32.dp)
        )
    }
}

/**
 * Компактная панель цветов для главного экрана
 */
@Composable
fun ColorPanel(
    colorState: ColorState,
    onBackgroundClick: () -> Unit,
    onColor1Click: () -> Unit,
    onColor2Click: () -> Unit,
    onGradientClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.s)
    ) {
        // Цвет фона
        ColorButton(
            colorName = "BG COLOR",
            selectedColor = colorState.background,
            onClick = onBackgroundClick,
            modifier = Modifier.weight(1f)
        )
        
        // Цвета символов
        when (val symbols = colorState.symbols) {
            is SymbolPaint.Solid -> {
                ColorButton(
                    colorName = "COLOR #2",
                    selectedColor = symbols.color,
                    onClick = onColor1Click,
                    modifier = Modifier.weight(1f)
                )
                ColorButton(
                    colorName = "COLOR #2",
                    selectedColor = null,
                    isEnabled = false,
                    onClick = onColor2Click,
                    modifier = Modifier.weight(1f)
                )
                ColorButton(
                    colorName = "GRADIENT",
                    selectedColor = null,
                    isEnabled = false,
                    onClick = onGradientClick,
                    modifier = Modifier.weight(1f)
                )
            }
            is SymbolPaint.Gradient -> {
                ColorButton(
                    colorName = "COLOR #1",
                    selectedColor = null,
                    isEnabled = false,
                    onClick = onColor1Click,
                    modifier = Modifier.weight(1f)
                )
                ColorButton(
                    colorName = "COLOR #2",
                    selectedColor = null,
                    isEnabled = false,
                    onClick = onColor2Click,
                    modifier = Modifier.weight(1f)
                )
                ColorButton(
                    colorName = "GRADIENT",
                    selectedColor = symbols.start, // Показываем первый цвет градиента
                    onClick = onGradientClick,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}
