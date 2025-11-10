package com.raux.myapplication_32.engine

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import kotlin.math.*
import com.raux.myapplication_32.data.models.EffectType
import com.raux.myapplication_32.data.models.EffectParams

/**
 * Новая модульная версия движка.
 *
 * Идея:
 * 1) GridPlanner — подбирает сетку (cols/rows) и размер шрифта по реальным метрикам глифов.
 * 2) Sampler — быстро считает среднюю яркость каждой ячейки через интегральное изображение.
 * 3) PaletteMapper — переводит яркости в символы (поддержка dithering и jitter).
 * 4) ASCIIEngineV2 — оркестратор: планирует, сэмплирует и отдаёт результат для UI.
 *
 * ВАЖНО: сюда передавайте размеры экрана в PX (не dp), иначе получите «пустой хвост» снизу.
 */

// -----------------------------
// Модель результата
// -----------------------------

data class Grid(
    val cols: Int,
    val rows: Int,
    val fontPx: Float,
    val charWidthPx: Float,
    val lineHeightPx: Float,
    val clamped: Boolean
)

sealed interface RenderResult {
    data class Text(val ascii: String, val grid: Grid) : RenderResult
    data class Image(val bitmap: Bitmap) : RenderResult
}

// -----------------------------
// Палитры символов (моно-дружественные)
// -----------------------------

object Palettes {
    // Безопасная моноширинная палитра (10 градаций)
    private const val ASCII_SAFE = " .:-=+*#%@"

    // Компактные блоки — одинаковая ширина почти везде
    val BLOCKS = listOf(" ", "░", "▒", "▓", "█")

    fun forEffect(effectType: EffectType): List<String> = when (effectType) {
        EffectType.ASCII -> ASCII_SAFE.map { it.toString() }
        EffectType.SQUARES -> BLOCKS
        EffectType.CIRCLES -> BLOCKS // безопасная замена проблемным кругам
        EffectType.DIAMONDS -> BLOCKS
        EffectType.SHAPES -> BLOCKS
    }
}

// -----------------------------
// GridPlanner — подбор сетки по реальным метрикам
// -----------------------------

object GridPlanner {
    private fun measureMetrics(
        palette: List<String>,
        textSizePx: Float,
        letterSpacingEm: Float = 0f
    ): Pair<Float, Float> {
        val paint = Paint().apply {
            isAntiAlias = true
            typeface = android.graphics.Typeface.MONOSPACE
            textSize = textSizePx
            letterSpacing = letterSpacingEm // EM, НЕ sp!
        }
        var maxW = 0f
        for (g in palette) maxW = max(maxW, paint.measureText(g))
        val fm = paint.fontMetrics
        val lineH = ceil((fm.descent - fm.ascent + fm.leading).toDouble()).toFloat()
        return maxW to lineH
    }

    /**
     * Планирование сетки. Возвращает Grid с актуальными метриками.
     * @param cellPercent 0f..1f
     * @param maxCells кап по производительности для текстового рендера
     */
    fun plan(
        screenWidthPx: Int,
        screenHeightPx: Int,
        cellPercent: Float,
        maxCells: Int,
        palette: List<String>,
        baseFontPx: Float,
        letterSpacingEm: Float = 0f
    ): Grid {
        // Диапазон желаемых размеров сетки
        val targetCols = (60 + (200 - 60) * cellPercent).toInt()
        val targetRows = (40 + (150 - 40) * cellPercent).toInt()

        // Итеративная подгонка размера шрифта, чтобы сетка влезла ровно
        var fontPx = baseFontPx
        repeat(2) {
            val (charW, lineH) = measureMetrics(palette, fontPx, letterSpacingEm)
            val maxCols = floor(screenWidthPx / charW).toInt().coerceAtLeast(4)
            val maxRows = floor(screenHeightPx / lineH).toInt().coerceAtLeast(4)
            val cols = min(targetCols, maxCols)
            val rows = min(targetRows, maxRows)
            val scaleW = screenWidthPx / (cols * charW)
            val scaleH = screenHeightPx / (rows * lineH)
            val safeScale = (min(scaleW, scaleH) * 0.985f)
            fontPx = (fontPx * safeScale).coerceIn(10f, 48f)
        }

        // Финальные метрики
        val (charW, lineH) = measureMetrics(palette, fontPx, letterSpacingEm)
        var cols = floor(screenWidthPx / charW).toInt().coerceAtLeast(4)
        var rows = floor(screenHeightPx / lineH).toInt().coerceAtLeast(4)

        // Кэп по количеству ячеек
        val cells = cols * rows
        var clamped = false
        if (cells > maxCells) {
            val k = sqrt(maxCells.toFloat() / cells)
            cols = max(8, floor(cols * k).toInt())
            rows = max(8, floor(rows * k).toInt())
            clamped = true
        }
        return Grid(cols, rows, fontPx, charW, lineH, clamped)
    }
}

// -----------------------------
// Sampler — интегральное изображение
// -----------------------------

object Sampler {
    private fun toGray(bitmap: Bitmap): IntArray {
        val w = bitmap.width; val h = bitmap.height
        val px = IntArray(w * h)
        bitmap.getPixels(px, 0, w, 0, 0, w, h)
        for (i in px.indices) {
            val p = px[i]
            val r = (p shr 16) and 0xFF
            val g = (p shr 8) and 0xFF
            val b = p and 0xFF
            px[i] = (0.299f * r + 0.587f * g + 0.114f * b).toInt()
        }
        return px
    }

    private fun buildIntegral(gray: IntArray, w: Int, h: Int): LongArray {
        val out = LongArray((w + 1) * (h + 1))
        var idx = 0
        for (y in 1..h) {
            var row = 0L
            for (x in 1..w) {
                row += gray[idx++]
                out[y * (w + 1) + x] = out[(y - 1) * (w + 1) + x] + row
            }
        }
        return out
    }

    private fun rectAvg(ii: LongArray, w: Int, x0: Int, y0: Int, x1: Int, y1: Int): Int {
        val A = ii[y0 * (w + 1) + x0]
        val B = ii[y0 * (w + 1) + x1]
        val C = ii[y1 * (w + 1) + x0]
        val D = ii[y1 * (w + 1) + x1]
        val sum = D - B - C + A
        val area = max(1, (x1 - x0) * (y1 - y0))
        return (sum / area).toInt().coerceIn(0, 255)
    }

    /**
     * Возвращает яркости (0..255) по ячейкам сетки cols*rows.
     */
    fun luminanceGrid(
        bitmap: Bitmap,
        cols: Int,
        rows: Int,
        blur: Int = 0,
        gamma: Float = 1.2f
    ): IntArray {
        // Лёгкий блюр — опционально, чтобы сгладить шум
        val src = if (blur > 0) Blur.applyBoxBlur(bitmap, max(1, (blur / 10f).toInt())) else bitmap
        val w = src.width; val h = src.height
        val gray = toGray(src)
        val ii = buildIntegral(gray, w, h)

        val out = IntArray(cols * rows)
        var idx = 0
        for (r in 0 until rows) {
            val y0 = (r * h) / rows
            val y1 = ((r + 1) * h) / rows
            for (c in 0 until cols) {
                val x0 = (c * w) / cols
                val x1 = ((c + 1) * w) / cols
                var v = rectAvg(ii, w, x0, y0, x1, y1)
                // gamma-коррекция к светлоте
                val nv = (v / 255f).toDouble().pow(1.0 / gamma).toFloat()
                out[idx++] = (nv * 255f).toInt().coerceIn(0, 255)
            }
        }
        if (src !== bitmap) src.recycle()
        return out
    }
}

// -----------------------------
// Blur (Box Blur)
// -----------------------------

object Blur {
    fun applyBoxBlur(bitmap: Bitmap, radius: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val result = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        val temp = IntArray(width * height)

        // Горизонтально
        for (y in 0 until height) {
            var rSum = 0; var gSum = 0; var bSum = 0
            val base = y * width
            for (x in 0 until width) {
                if (x == 0) {
                    rSum = 0; gSum = 0; bSum = 0
                    for (dx in -radius..radius) {
                        val nx = (dx).coerceIn(0, width - 1)
                        val p = pixels[base + nx]
                        rSum += (p shr 16) and 0xFF
                        gSum += (p shr 8) and 0xFF
                        bSum += p and 0xFF
                    }
                } else {
                    val xOut = (x - radius - 1).coerceIn(0, width - 1)
                    val xIn = (x + radius).coerceIn(0, width - 1)
                    val pOut = pixels[base + xOut]
                    val pIn = pixels[base + xIn]
                    rSum += ((pIn shr 16) and 0xFF) - ((pOut shr 16) and 0xFF)
                    gSum += ((pIn shr 8) and 0xFF) - ((pOut shr 8) and 0xFF)
                    bSum += (pIn and 0xFF) - (pOut and 0xFF)
                }
                val count = radius * 2 + 1
                temp[base + x] = Color.rgb(rSum / count, gSum / count, bSum / count)
            }
        }

        // Вертикально
        for (x in 0 until width) {
            var rSum = 0; var gSum = 0; var bSum = 0
            for (y in 0 until height) {
                val idx = y * width + x
                if (y == 0) {
                    rSum = 0; gSum = 0; bSum = 0
                    for (dy in -radius..radius) {
                        val ny = (dy).coerceIn(0, height - 1)
                        val p = temp[ny * width + x]
                        rSum += (p shr 16) and 0xFF
                        gSum += (p shr 8) and 0xFF
                        bSum += p and 0xFF
                    }
                } else {
                    val yOut = (y - radius - 1).coerceIn(0, height - 1)
                    val yIn = (y + radius).coerceIn(0, height - 1)
                    val pOut = temp[yOut * width + x]
                    val pIn = temp[yIn * width + x]
                    rSum += ((pIn shr 16) and 0xFF) - ((pOut shr 16) and 0xFF)
                    gSum += ((pIn shr 8) and 0xFF) - ((pOut shr 8) and 0xFF)
                    bSum += (pIn and 0xFF) - (pOut and 0xFF)
                }
                val count = radius * 2 + 1
                pixels[idx] = Color.rgb(rSum / count, gSum / count, bSum / count)
            }
        }

        result.setPixels(pixels, 0, width, 0, 0, width, height)
        return result
    }
}

// -----------------------------
// PaletteMapper — из яркости в символы (с dithering и jitter)
// -----------------------------

object PaletteMapper {
    // Bayer 8x8 (0..63)
    private val BAYER_8 = arrayOf(
        intArrayOf(0, 32, 8, 40, 2, 34, 10, 42),
        intArrayOf(48, 16, 56, 24, 50, 18, 58, 26),
        intArrayOf(12, 44, 4, 36, 14, 46, 6, 38),
        intArrayOf(60, 28, 52, 20, 62, 30, 54, 22),
        intArrayOf(3, 35, 11, 43, 1, 33, 9, 41),
        intArrayOf(51, 19, 59, 27, 49, 17, 57, 25),
        intArrayOf(15, 47, 7, 39, 13, 45, 5, 37),
        intArrayOf(63, 31, 55, 23, 61, 29, 53, 21)
    )

    fun map(
        luminance: IntArray, // 0..255, size = cols*rows
        cols: Int,
        rows: Int,
        palette: List<String>,
        jitter: Int = 0,     // 0..100
        dither: Boolean = false
    ): String {
        val n = palette.size
        val sb = StringBuilder(rows * (cols + 1))
        val jitterRange = (jitter / 15).coerceAtLeast(0) // ±N индексов

        var idx = 0
        for (r in 0 until rows) {
            for (c in 0 until cols) {
                val v = luminance[idx++]
                var nv = v / 255f
                if (dither) {
                    val t = (BAYER_8[r and 7][c and 7] / 63f) - 0.5f // -0.5..+0.5
                    nv = (nv + t * (1f / n)).coerceIn(0f, 1f)
                }
                var pi = floor(nv * (n - 1)).toInt()
                if (jitterRange > 0) {
                    pi = (pi + (kotlin.random.Random.nextInt(-jitterRange, jitterRange + 1)))
                        .coerceIn(0, n - 1)
                }
                sb.append(palette[pi])
            }
            if (r != rows - 1) sb.append('\n') // без пустой строки в конце
        }
        return sb.toString()
    }
}

// -----------------------------
// Основной оркестратор
// -----------------------------

object ASCIIEngineV2 {
    /**
     * Рендер текста. Возвращает готовую строку и метрики сетки для корректного отображения в Compose.
     *
     * В UI:
     * Text(
     *   text = result.ascii,
     *   fontSize = with(LocalDensity.current){ result.grid.fontPx.toSp() },
     *   fontFamily = FontFamily.Monospace,
     *   softWrap = false,
     *   overflow = TextOverflow.Clip,
     *   maxLines = result.grid.rows,
     *   lineHeight = with(LocalDensity.current){ result.grid.lineHeightPx.toSp() },
     *   style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
     * )
     */
    fun renderText(
        source: Bitmap,
        effectType: EffectType,
        params: EffectParams,
        screenWidthPx: Int,
        screenHeightPx: Int,
        // UI density не нужен тут — передаём/возвращаем всё в PX
        baseFontPx: Float = 24f,
        letterSpacingEm: Float = 0f,
        maxCells: Int = 18_000,
        dither: Boolean = true,
        gamma: Float = 1.25f
    ): RenderResult.Text {
        val cellPercent = (params.cell / 100f).coerceIn(0f, 1f)
        val palette = Palettes.forEffect(effectType)

        val grid = GridPlanner.plan(
            screenWidthPx = screenWidthPx,
            screenHeightPx = screenHeightPx,
            cellPercent = cellPercent,
            maxCells = maxCells,
            palette = palette,
            baseFontPx = baseFontPx,
            letterSpacingEm = letterSpacingEm
        )

        val lum = Sampler.luminanceGrid(
            bitmap = source,
            cols = grid.cols,
            rows = grid.rows,
            blur = params.softy,
            gamma = gamma
        )

        val ascii = PaletteMapper.map(
            luminance = lum,
            cols = grid.cols,
            rows = grid.rows,
            palette = palette,
            jitter = params.jitter,
            dither = dither
        )

        return RenderResult.Text(ascii, grid)
    }

    /**
     * Пререндер в Bitmap (когда текст слишком тяжёлый или нужен стабильный fill).
     * Быстрее будет через атлас глифов, но для простоты — рисуем построчно.
     */
    fun renderBitmap(
        text: String,
        grid: Grid,
        backgroundColor: Int = Color.BLACK,
        textColor: Int = Color.WHITE
    ): RenderResult.Image {
        val paint = Paint().apply {
            isAntiAlias = true
            typeface = android.graphics.Typeface.MONOSPACE
            color = textColor
            textSize = grid.fontPx
            letterSpacing = 0f
        }
        val fm = paint.fontMetrics
        val lineH = grid.lineHeightPx
        val colsW = (grid.cols * grid.charWidthPx).roundToInt()
        val rowsH = (grid.rows * lineH).roundToInt()

        val bmp = Bitmap.createBitmap(colsW, rowsH, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        canvas.drawColor(backgroundColor)

        var y = -fm.ascent
        val lines = text.split('\n')
        for (line in lines) {
            canvas.drawText(line, 0f, y, paint)
            y += lineH
        }
        return RenderResult.Image(bmp)
    }
}

// -----------------------------
// Пример использования (вызов из вашего кода)
// -----------------------------
/*
val result = ASCIIEngineV2.renderText(
    source = cameraBitmap,
    effectType = currentEffect,
    params = effectParams, // должен содержать: cell (0..100), softy (0..100), jitter (0..100)
    screenWidthPx = screenWidthPx,
    screenHeightPx = screenHeightPx,
    baseFontPx = 24f,
    letterSpacingEm = 0f,
    maxCells = 18_000,
    dither = true,
    gamma = 1.25f
)

// Compose:
Text(
    text = result.ascii,
    fontSize = with(LocalDensity.current){ result.grid.fontPx.toSp() },
    fontFamily = FontFamily.Monospace,
    softWrap = false,
    overflow = TextOverflow.Clip,
    maxLines = result.grid.rows,
    lineHeight = with(LocalDensity.current){ result.grid.lineHeightPx.toSp() },
    style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
)

// Если cells слишком много или нужен идеальный fill, рендерим Bitmap:
val img = ASCIIEngineV2.renderBitmap(result.ascii, result.grid)
Image(bitmap = img.bitmap.asImageBitmap(), contentDescription = null)
*/
