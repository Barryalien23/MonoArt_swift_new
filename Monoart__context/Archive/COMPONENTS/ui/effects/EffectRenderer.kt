package com.digitalreality.ui.effects

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.digitalreality.data.models.*
import kotlin.math.sin
import kotlin.math.cos
import kotlin.random.Random

/**
 * Рендерер визуальных эффектов поверх превью камеры
 */
@Composable
fun EffectRenderer(
    effectType: EffectType,
    params: EffectParams,
    colorState: ColorState,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    
    // Анимация для Jitter
    var animationTime by remember { mutableStateOf(0f) }
    
    LaunchedEffect(params.jitter) {
        if (params.jitter > 0) {
            while (true) {
                animationTime += 0.016f // ~60fps
                kotlinx.coroutines.delay(16)
            }
        }
    }
    
    Canvas(
        modifier = modifier.fillMaxSize()
    ) {
        drawEffect(
            effectType = effectType,
            params = params,
            colorState = colorState,
            animationTime = animationTime
        )
    }
}

private fun DrawScope.drawEffect(
    effectType: EffectType,
    params: EffectParams,
    colorState: ColorState,
    animationTime: Float
) {
    val cellSize = calculateCellSize(params.cell)
    val cols = (size.width / cellSize).toInt()
    val rows = (size.height / cellSize).toInt()
    
    for (row in 0 until rows) {
        for (col in 0 until cols) {
            val x = col * cellSize
            val y = row * cellSize
            
            // Jitter эффект
            val jitterX = if (params.jitter > 0) {
                (sin(animationTime * 5 + col + row) * params.jitter / 100f * 10f)
            } else 0f
            
            val jitterY = if (params.jitter > 0) {
                (cos(animationTime * 3 + col * 0.5f + row * 0.7f) * params.jitter / 100f * 10f)
            } else 0f
            
            val finalX = x + jitterX
            val finalY = y + jitterY
            
            // Определяем цвет символа/фигуры
            val symbolColor = when (colorState.symbols) {
                is SymbolPaint.Solid -> colorState.symbols.color
                is SymbolPaint.Gradient -> {
                    // Линейный горизонтальный градиент
                    val progress = col.toFloat() / cols.toFloat()
                    lerp(colorState.symbols.start, colorState.symbols.end, progress)
                }
            }
            
            // Рисуем эффект
            when (effectType) {
                EffectType.ASCII -> drawAsciiEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params,
                    seed = col + row * cols
                )
                EffectType.CIRCLES -> drawCircleEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params
                )
                EffectType.SQUARES -> drawSquareEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params
                )
                EffectType.TRIANGLE -> drawTriangleEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params
                )
                EffectType.DIAMONDS -> drawDiamondEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params
                )
                EffectType.SHAPES -> drawShapesEffect(
                    x = finalX,
                    y = finalY,
                    size = cellSize,
                    color = symbolColor,
                    params = params,
                    seed = col + row * cols
                )
            }
        }
    }
}

private fun calculateCellSize(cellParam: Int): Float {
    // Преобразуем параметр 0-100 в размер ячейки (минимум 8dp, максимум 32dp)
    return (8 + (cellParam / 100f) * 24f)
}

private fun DrawScope.drawAsciiEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams,
    seed: Int
) {
    // ASCII символы разной плотности
    val asciiChars = listOf(".", ":", "-", "=", "+", "*", "#", "%", "@")
    val charIndex = (seed + (params.softy / 10)) % asciiChars.size
    
    // TODO: Реализовать отрисовку ASCII символов
    // Пока рисуем точки разного размера
    val radius = size * 0.2f * (1 + params.softy / 100f)
    drawCircle(
        color = color,
        radius = radius,
        center = androidx.compose.ui.geometry.Offset(x + size/2, y + size/2)
    )
}

private fun DrawScope.drawCircleEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams
) {
    val radius = size * 0.3f * (1 + params.softy / 100f)
    val cornerRadius = params.edje / 100f * radius
    
    drawCircle(
        color = color,
        radius = radius,
        center = androidx.compose.ui.geometry.Offset(x + size/2, y + size/2)
    )
}

private fun DrawScope.drawSquareEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams
) {
    val rectSize = size * 0.6f * (1 + params.softy / 100f)
    val cornerRadius = params.edje / 100f * rectSize * 0.5f
    
    drawRoundRect(
        color = color,
        topLeft = androidx.compose.ui.geometry.Offset(
            x + (size - rectSize) / 2,
            y + (size - rectSize) / 2
        ),
        size = androidx.compose.ui.geometry.Size(rectSize, rectSize),
        cornerRadius = androidx.compose.ui.geometry.CornerRadius(cornerRadius)
    )
}

private fun DrawScope.drawTriangleEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams
) {
    val triangleSize = size * 0.6f * (1 + params.softy / 100f)
    val centerX = x + size / 2
    val centerY = y + size / 2
    val halfSize = triangleSize / 2
    
    val path = Path().apply {
        moveTo(centerX, centerY - halfSize)
        lineTo(centerX - halfSize, centerY + halfSize)
        lineTo(centerX + halfSize, centerY + halfSize)
        close()
    }
    
    drawPath(
        path = path,
        color = color
    )
}

private fun DrawScope.drawDiamondEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams
) {
    val diamondSize = size * 0.6f * (1 + params.softy / 100f)
    val centerX = x + size / 2
    val centerY = y + size / 2
    val halfSize = diamondSize / 2
    
    val path = Path().apply {
        moveTo(centerX, centerY - halfSize)
        lineTo(centerX + halfSize, centerY)
        lineTo(centerX, centerY + halfSize)
        lineTo(centerX - halfSize, centerY)
        close()
    }
    
    drawPath(
        path = path,
        color = color
    )
}

private fun DrawScope.drawShapesEffect(
    x: Float,
    y: Float,
    size: Float,
    color: Color,
    params: EffectParams,
    seed: Int
) {
    // Случайно выбираем форму на основе seed
    when (seed % 4) {
        0 -> drawCircleEffect(x, y, size, color, params)
        1 -> drawSquareEffect(x, y, size, color, params)
        2 -> drawTriangleEffect(x, y, size, color, params)
        3 -> drawDiamondEffect(x, y, size, color, params)
    }
}

private fun lerp(start: Color, end: Color, fraction: Float): Color {
    return Color(
        red = start.red + fraction * (end.red - start.red),
        green = start.green + fraction * (end.green - start.green),
        blue = start.blue + fraction * (end.blue - start.blue),
        alpha = start.alpha + fraction * (end.alpha - start.alpha)
    )
}
