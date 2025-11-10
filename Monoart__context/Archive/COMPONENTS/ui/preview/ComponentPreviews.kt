package com.digitalreality.ui.preview

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import com.digitalreality.R
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.digitalreality.data.models.*
import com.digitalreality.ui.components.*
import com.digitalreality.ui.theme.*

// Реальные иконки из ресурсов
@Composable
fun getUploadIcon() = ImageVector.vectorResource(R.drawable.ic_upload)
@Composable
fun getCameraIcon() = ImageVector.vectorResource(R.drawable.ic_rotate_camera)
@Composable
fun getCellIcon() = ImageVector.vectorResource(R.drawable.ic_setting_cell)
@Composable
fun getJitterIcon() = ImageVector.vectorResource(R.drawable.ic_setting_jitter)
@Composable
fun getEdgeIcon() = ImageVector.vectorResource(R.drawable.ic_setting_edge)
@Composable
fun getSoftyIcon() = ImageVector.vectorResource(R.drawable.ic_setting_softy)
@Composable
fun getAsciiIcon() = ImageVector.vectorResource(R.drawable.ic_effect_ascii)

@Preview(name = "Capture Button", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewCaptureButton() {
    DigitalRealityTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Обычное состояние
            CaptureButton(
                onClick = { },
                isCapturing = false
            )
            
            // Состояние захвата
            CaptureButton(
                onClick = { },
                isCapturing = true
            )
        }
    }
}

@Preview(name = "Function Buttons", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewFunctionButtons() {
    DigitalRealityTheme {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            FunctionButton(
                icon = getUploadIcon(),
                onClick = { }
            )
            
            FunctionButton(
                icon = getCameraIcon(),
                onClick = { }
            )
            
            FunctionButton(
                icon = getUploadIcon(),
                onClick = { },
                enabled = false
            )
        }
    }
}

@Preview(name = "Effect Button", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewEffectButton() {
    DigitalRealityTheme {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            EffectButton(
                effectName = "ASCII",
                icon = getAsciiIcon(),
                isSelected = false,
                onClick = { }
            )
            
            EffectButton(
                effectName = "ASCII",
                icon = getAsciiIcon(),
                isSelected = true,
                onClick = { }
            )
        }
    }
}

@Preview(name = "Setting Buttons", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewSettingButtons() {
    DigitalRealityTheme {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            SettingButton(
                paramName = "CELL",
                icon = getCellIcon(),
                value = 0,
                onClick = { },
                modifier = Modifier.weight(1f)
            )
            
            SettingButton(
                paramName = "JITTER",
                icon = getJitterIcon(),
                value = 25,
                onClick = { },
                modifier = Modifier.weight(1f)
            )
            
            SettingButton(
                paramName = "EDGE",
                icon = getEdgeIcon(),
                value = 75,
                onClick = { },
                modifier = Modifier.weight(1f)
            )
            
            SettingButton(
                paramName = "SOFTY",
                icon = getSoftyIcon(),
                value = 100,
                onClick = { },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Preview(name = "Color Buttons", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewColorButtons() {
    DigitalRealityTheme {
        Row(
            modifier = Modifier.padding(16.dp),
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

@Preview(name = "Effect Parameter Slider", showBackground = true, backgroundColor = 0xFF000000)
@Composable
fun PreviewEffectParameterSlider() {
    DigitalRealityTheme {
        EffectParameterSlider(
            paramName = "CELL",
            icon = getCellIcon(),
            value = 45,
            onValueChange = { },
            onBackClick = { }
        )
    }
}

@Preview(name = "Main Settings Panel", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewMainSettingsPanel() {
    DigitalRealityTheme {
        val mockParams = EffectParams(
            cell = 30,
            jitter = 15,
            edje = 60,
            softy = 80
        )
        
        val mockColorState = ColorState(
            background = Color.Black,
            symbols = SymbolPaint.Solid(Color.White)
        )
        
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CurrentEffectDisplay(
                    effect = EffectType.ASCII,
                    onClick = { }
                )
                
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    EffectSettingsPanel(
                        params = mockParams,
                        onParamClick = { }
                    )
                    
                    ColorPanel(
                        colorState = mockColorState,
                        onBackgroundClick = { },
                        onColor1Click = { },
                        onColor2Click = { },
                        onGradientClick = { }
                    )
                }
            }
        }
    }
}

@Preview(name = "Button Block Layout", showBackground = true, backgroundColor = 0xFF272727)
@Composable
fun PreviewButtonBlockLayout() {
    DigitalRealityTheme {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Имитация кнопок поверх панели настроек
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                FunctionButton(
                    icon = mockUploadIcon,
                    onClick = { }
                )
                
                CaptureButton(
                    onClick = { },
                    isCapturing = false
                )
                
                FunctionButton(
                    icon = mockCameraIcon,
                    onClick = { }
                )
            }
        }
    }
}
