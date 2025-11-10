package com.digitalreality.data.models

import androidx.camera.core.CameraSelector

/**
 * Состояние камеры
 */
enum class CameraFacing {
    FRONT,
    BACK;
    
    fun toCameraSelector(): CameraSelector = when (this) {
        FRONT -> CameraSelector.DEFAULT_FRONT_CAMERA
        BACK -> CameraSelector.DEFAULT_BACK_CAMERA
    }
}

/**
 * Состояние захвата фото
 */
sealed interface CaptureState {
    object Idle : CaptureState
    object Capturing : CaptureState
    data class Success(val imageUri: String) : CaptureState
    data class Error(val message: String) : CaptureState
}
