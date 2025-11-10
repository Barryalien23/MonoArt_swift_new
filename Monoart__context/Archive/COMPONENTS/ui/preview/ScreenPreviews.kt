package com.digitalreality.ui.preview

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import com.digitalreality.R
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.digitalreality.data.models.*
import com.digitalreality.ui.components.*
import com.digitalreality.ui.theme.*

@Preview(name = "Effect Picker Screen", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewEffectPicker() {
    DigitalRealityTheme {
        EffectPicker(
            currentEffect = EffectType.ASCII,
            effects = EffectType.values().toList(),
            onEffectSelected = { },
            onBackClick = { }
        )
    }
}

@Preview(name = "Color Picker Screen", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewColorPickerScreen() {
    DigitalRealityTheme {
        ColorPickerScreen(
            colorState = ColorState(
                background = Color.Black,
                symbols = SymbolPaint.Solid(Color.White)
            ),
            selectedMode = ColorPickerMode.BACKGROUND,
            onModeSelected = { },
            onBackgroundColorChanged = { },
            onSymbolColorChanged = { },
            onGradientChanged = { _, _ -> },
            onBackClick = { }
        )
    }
}

@Preview(name = "Effect Settings Screen", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewEffectSettingsScreen() {
    DigitalRealityTheme {
        EffectSettingsScreen(
            params = EffectParams(
                cell = 45,
                jitter = 20,
                edje = 75,
                softy = 60
            ),
            selectedParam = "Cell",
            onParamSelected = { },
            onParamValueChanged = { _, _ -> },
            onBackClick = { }
        )
    }
}

@Preview(name = "Main Screen Layout", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewMainScreenLayout() {
    DigitalRealityTheme {
        // Упрощенная версия главного экрана для превью
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.BackgroundDark)
        ) {
            // Имитация превью камеры
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(AppColors.BackgroundDark)
            )
            
            // Панель настроек внизу
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.Black)
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Эффект
                    EffectButton(
                        effectName = "ASCII",
                        icon = ImageVector.vectorResource(R.drawable.ic_effect_ascii),
                        isSelected = true,
                        onClick = { }
                    )
                    
                    // Настройки
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Параметры эффекта
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            SettingButton(
                                paramName = "CELL",
                                icon = ImageVector.vectorResource(R.drawable.ic_setting_cell),
                                value = 30,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                            SettingButton(
                                paramName = "JITTER",
                                icon = ImageVector.vectorResource(R.drawable.ic_setting_jitter),
                                value = 0,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                            SettingButton(
                                paramName = "EDGE",
                                icon = ImageVector.vectorResource(R.drawable.ic_setting_edge),
                                value = 0,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                            SettingButton(
                                paramName = "SOFTY",
                                icon = ImageVector.vectorResource(R.drawable.ic_setting_softy),
                                value = 0,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        
                        // Цвета
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            ColorButton(
                                colorName = "BG COLOR",
                                selectedColor = Color.Black,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                            ColorButton(
                                colorName = "COLOR #2",
                                selectedColor = Color.White,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                            ColorButton(
                                colorName = "GRADIENT",
                                selectedColor = null,
                                isEnabled = false,
                                onClick = { },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
        }
    }
}
