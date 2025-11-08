package com.digitalreality.data.models

import androidx.compose.runtime.Stable
import androidx.compose.ui.graphics.Color

/**
 * Способы окраски символов/фигур эффекта
 */
sealed interface SymbolPaint {
    @Stable
    data class Solid(val color: Color) : SymbolPaint
    
    @Stable
    data class Gradient(
        val start: Color, 
        val end: Color
        // Направление фиксировано (линейный горизонтальный)
    ) : SymbolPaint
}

/**
 * Состояние цветовой схемы
 */
@Stable
data class ColorState(
    val background: Color = Color.Black,           // Фон всегда сплошной
    val symbols: SymbolPaint = SymbolPaint.Solid(Color.White)  // Символы - цвет или градиент
)

/**
 * Режимы выбора цвета
 */
enum class ColorPickerMode {
    COLOR_1,    // Первый цвет символов
    COLOR_2,    // Второй цвет символов  
    GRADIENT,   // Режим градиента
    BACKGROUND  // Цвет фона
}
