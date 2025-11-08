package com.digitalreality.ui.theme

import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.unit.dp

// Эффекты из StylesToken.json
object AppEffects {
    // Shadow blur - backdrop-filter: blur(2.7px)
    val shadowBlur = BlurEffect(2.7f, TileMode.Clamp)
    
    // Box shadows (эмуляция через elevation в Compose)
    val shadowElevation = 8.dp
    val blockShadowElevation = 16.dp
    val knobShadowElevation = 3.dp
}
