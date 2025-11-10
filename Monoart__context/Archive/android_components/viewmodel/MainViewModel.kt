package com.digitalreality.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digitalreality.data.models.*
import kotlinx.coroutines.launch

/**
 * Основное состояние приложения
 */
data class MainUiState(
    val selectedEffect: EffectType = EffectType.ASCII,
    val effectParams: EffectParams = EffectParams(),
    val colorState: ColorState = ColorState(),
    val cameraFacing: CameraFacing = CameraFacing.BACK,
    val captureState: CaptureState = CaptureState.Idle,
    val isFirstLaunch: Boolean = true,
    val showEffectPicker: Boolean = false,
    val showEffectSettings: Boolean = false,
    val showColorPicker: Boolean = false,
    val selectedSettingParam: String? = null, // "Cell"|"Jitter"|"Edje"|"Softy"
    val colorPickerMode: ColorPickerMode? = null
)

class MainViewModel : ViewModel() {
    
    var uiState by mutableStateOf(MainUiState())
        private set
    
    // Действия для эффектов
    fun selectEffect(effect: EffectType) {
        uiState = uiState.copy(
            selectedEffect = effect,
            showEffectPicker = false
        )
    }
    
    fun showEffectPicker() {
        uiState = uiState.copy(showEffectPicker = true)
    }
    
    fun hideEffectPicker() {
        uiState = uiState.copy(showEffectPicker = false)
    }
    
    // Действия для настроек эффекта
    fun showEffectSettings(param: String) {
        uiState = uiState.copy(
            showEffectSettings = true,
            selectedSettingParam = param
        )
    }
    
    fun hideEffectSettings() {
        uiState = uiState.copy(
            showEffectSettings = false,
            selectedSettingParam = null
        )
    }
    
    fun updateEffectParam(param: String, value: Int) {
        val clampedValue = value.coerceIn(0, 100)
        val newParams = when (param) {
            "Cell" -> uiState.effectParams.copy(cell = clampedValue)
            "Jitter" -> uiState.effectParams.copy(jitter = clampedValue)
            "Edje" -> uiState.effectParams.copy(edje = clampedValue)
            "Softy" -> uiState.effectParams.copy(softy = clampedValue)
            else -> uiState.effectParams
        }
        uiState = uiState.copy(effectParams = newParams)
    }
    
    // Действия для цветов
    fun showColorPicker(mode: ColorPickerMode) {
        uiState = uiState.copy(
            showColorPicker = true,
            colorPickerMode = mode
        )
    }
    
    fun hideColorPicker() {
        uiState = uiState.copy(
            showColorPicker = false,
            colorPickerMode = null
        )
    }
    
    fun updateBackgroundColor(color: androidx.compose.ui.graphics.Color) {
        uiState = uiState.copy(
            colorState = uiState.colorState.copy(background = color)
        )
    }
    
    fun updateSymbolColor(color: androidx.compose.ui.graphics.Color) {
        uiState = uiState.copy(
            colorState = uiState.colorState.copy(
                symbols = SymbolPaint.Solid(color)
            )
        )
    }
    
    fun updateSymbolGradient(startColor: androidx.compose.ui.graphics.Color, endColor: androidx.compose.ui.graphics.Color) {
        uiState = uiState.copy(
            colorState = uiState.colorState.copy(
                symbols = SymbolPaint.Gradient(startColor, endColor)
            )
        )
    }
    
    // Действия для камеры
    fun switchCamera() {
        uiState = uiState.copy(
            cameraFacing = when (uiState.cameraFacing) {
                CameraFacing.FRONT -> CameraFacing.BACK
                CameraFacing.BACK -> CameraFacing.FRONT
            }
        )
    }
    
    fun capturePhoto() {
        viewModelScope.launch {
            uiState = uiState.copy(captureState = CaptureState.Capturing)
            // TODO: Реализовать захват фото с эффектами
            // Пока эмуляция
            kotlinx.coroutines.delay(500)
            uiState = uiState.copy(captureState = CaptureState.Success("photo_uri"))
        }
    }
    
    fun resetCaptureState() {
        uiState = uiState.copy(captureState = CaptureState.Idle)
    }
    
    fun completeFirstLaunch() {
        uiState = uiState.copy(isFirstLaunch = false)
    }
}
