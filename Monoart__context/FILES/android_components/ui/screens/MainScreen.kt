package com.digitalreality.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.digitalreality.R
import com.digitalreality.data.models.ColorPickerMode
import com.digitalreality.ui.components.*
import com.digitalreality.ui.theme.*
import com.digitalreality.viewmodel.MainViewModel

/**
 * Главный экран приложения
 * Превью камеры + панель настроек + кнопки управления
 */
@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel()
) {
    val uiState by remember { derivedStateOf { viewModel.uiState } }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.BackgroundDark)
    ) {
        // Превью камеры (заглушка)
        CameraPreviewPlaceholder(
            modifier = Modifier.fillMaxSize()
        )
        
        // Панель настроек внизу
        SettingsPanel(
            uiState = uiState,
            onEffectClick = viewModel::showEffectPicker,
            onParamClick = viewModel::showEffectSettings,
            onBackgroundColorClick = { 
                viewModel.showColorPicker(ColorPickerMode.BACKGROUND) 
            },
            onColor1Click = { 
                viewModel.showColorPicker(ColorPickerMode.COLOR_1) 
            },
            onColor2Click = { 
                viewModel.showColorPicker(ColorPickerMode.COLOR_2) 
            },
            onGradientClick = { 
                viewModel.showColorPicker(ColorPickerMode.GRADIENT) 
            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
        )
        
        // Кнопки управления поверх панели настроек
        ButtonsOverlay(
            isCapturing = uiState.captureState is com.digitalreality.data.models.CaptureState.Capturing,
            onCaptureClick = viewModel::capturePhoto,
            onSwitchCameraClick = viewModel::switchCamera,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(bottom = ComponentSizes.settingsPanelHeight - 30.dp)
        )
    }
    
    // Модальные экраны
    if (uiState.showEffectPicker) {
        EffectPicker(
            currentEffect = uiState.selectedEffect,
            effects = com.digitalreality.data.models.EffectType.values().toList(),
            onEffectSelected = viewModel::selectEffect,
            onBackClick = viewModel::hideEffectPicker
        )
    }
    
    if (uiState.showEffectSettings) {
        EffectSettingsScreen(
            params = uiState.effectParams,
            selectedParam = uiState.selectedSettingParam,
            onParamSelected = viewModel::showEffectSettings,
            onParamValueChanged = viewModel::updateEffectParam,
            onBackClick = viewModel::hideEffectSettings
        )
    }
    
    if (uiState.showColorPicker && uiState.colorPickerMode != null) {
        ColorPickerScreen(
            colorState = uiState.colorState,
            selectedMode = uiState.colorPickerMode,
            onModeSelected = { mode -> viewModel.showColorPicker(mode) },
            onBackgroundColorChanged = viewModel::updateBackgroundColor,
            onSymbolColorChanged = viewModel::updateSymbolColor,
            onGradientChanged = viewModel::updateSymbolGradient,
            onBackClick = viewModel::hideColorPicker
        )
    }
}

@Composable
private fun CameraPreviewPlaceholder(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .background(AppColors.BackgroundDark),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "CAMERA PREVIEW",
            style = AppTypography.head1,
            color = AppColors.White40
        )
    }
}

@Composable
private fun SettingsPanel(
    uiState: com.digitalreality.viewmodel.MainUiState,
    onEffectClick: () -> Unit,
    onParamClick: (String) -> Unit,
    onBackgroundColorClick: () -> Unit,
    onColor1Click: () -> Unit,
    onColor2Click: () -> Unit,
    onGradientClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        AppColors.Black.copy(alpha = 0.8f),
                        AppColors.Black
                    )
                ),
                shape = RoundedCornerShape(
                    topStart = Roundings.l,
                    topEnd = Roundings.l
                )
            )
            .padding(Spacing.m),
        verticalArrangement = Arrangement.spacedBy(Spacing.s)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.s)
        ) {
            // Выбор эффекта
            CurrentEffectDisplay(
                effect = uiState.selectedEffect,
                onClick = onEffectClick
            )
            
            // Настройки параметров
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(Spacing.s)
            ) {
                EffectSettingsPanel(
                    params = uiState.effectParams,
                    onParamClick = onParamClick
                )
                
                ColorPanel(
                    colorState = uiState.colorState,
                    onBackgroundClick = onBackgroundColorClick,
                    onColor1Click = onColor1Click,
                    onColor2Click = onColor2Click,
                    onGradientClick = onGradientClick
                )
            }
        }
    }
}

@Composable
private fun ButtonsOverlay(
    isCapturing: Boolean,
    onCaptureClick: () -> Unit,
    onSwitchCameraClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.padding(horizontal = Spacing.l),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Кнопка загрузки (слева)
        FunctionButton(
            icon = ImageVector.vectorResource(R.drawable.ic_upload),
            onClick = { /* TODO: Implement upload */ },
            modifier = Modifier.size(ComponentSizes.buttonSmallHeight)
        )
        
        // Кнопка захвата фото (центр)
        CaptureButton(
            onClick = onCaptureClick,
            isCapturing = isCapturing,
            modifier = Modifier.size(ComponentSizes.captureButtonSize)
        )
        
        // Кнопка переключения камеры (справа)
        FunctionButton(
            icon = ImageVector.vectorResource(R.drawable.ic_rotate_camera),
            onClick = onSwitchCameraClick,
            modifier = Modifier.size(ComponentSizes.buttonSmallHeight)
        )
    }
}
