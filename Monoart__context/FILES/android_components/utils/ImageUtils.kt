package com.digitalreality.utils

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import androidx.camera.core.ImageProxy
import java.io.IOException

object ImageUtils {
    
    /**
     * Сохранение изображения в MediaStore
     */
    fun saveImageToMediaStore(
        context: Context,
        bitmap: Bitmap,
        displayName: String = "digital_reality_${System.currentTimeMillis()}.jpg"
    ): Uri? {
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/DigitalReality")
        }
        
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        
        return uri?.let { imageUri ->
            try {
                resolver.openOutputStream(imageUri)?.use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 95, outputStream)
                }
                imageUri
            } catch (e: IOException) {
                // Удаляем запись, если не удалось сохранить
                resolver.delete(imageUri, null, null)
                null
            }
        }
    }
    
    /**
     * Конвертация ImageProxy в Bitmap
     */
    fun imageProxyToBitmap(image: ImageProxy): Bitmap {
        val buffer = image.planes[0].buffer
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)
        
        // TODO: Реализовать конвертацию в зависимости от формата изображения
        // Это упрощенная версия, в реальном приложении нужно учитывать формат
        
        return android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    }
    
    /**
     * Применение эффекта к Bitmap
     */
    fun applyEffectToBitmap(
        bitmap: Bitmap,
        effectType: com.digitalreality.data.models.EffectType,
        params: com.digitalreality.data.models.EffectParams,
        colorState: com.digitalreality.data.models.ColorState
    ): Bitmap {
        // TODO: Реализовать применение эффектов к изображению
        // Это может быть сделано через Canvas, RenderScript или нативный код
        
        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = android.graphics.Canvas(mutableBitmap)
        
        // Применяем эффект (упрощенная версия)
        // В реальном приложении здесь должна быть логика рендеринга эффектов
        
        return mutableBitmap
    }
}
