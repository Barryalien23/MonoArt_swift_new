package com.digitalreality.data.models

import androidx.compose.runtime.Stable
import androidx.annotation.DrawableRes

/**
 * Типы визуальных эффектов
 */
enum class EffectType(val displayName: String, @DrawableRes val iconRes: Int) {
    ASCII("ASCII", R.drawable.ic_effect_ascii),
    SHAPES("SHAPES", R.drawable.ic_effect_shapes), 
    CIRCLES("CIRCLES", R.drawable.ic_effect_circles),
    SQUARES("SQUARES", R.drawable.ic_effect_squares),
    TRIANGLE("TRIANGLE", R.drawable.ic_effect_triangle),
    DIAMONDS("DIAMONDS", R.drawable.ic_effect_diamonds)
}

/**
 * Параметры эффекта (все в диапазоне 0..100)
 */
@Stable
data class EffectParams(
    val cell: Int = 50,    // Размер сетки
    val jitter: Int = 0,   // Скорость анимации
    val edje: Int = 0,     // Степень скругления
    val softy: Int = 0     // Размытие/смягчение
) {
    init {
        require(cell in 0..100) { "Cell must be in range 0..100" }
        require(jitter in 0..100) { "Jitter must be in range 0..100" }
        require(edje in 0..100) { "Edje must be in range 0..100" }
        require(softy in 0..100) { "Softy must be in range 0..100" }
    }
}
