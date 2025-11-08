package com.digitalreality.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.digitalreality.ui.theme.*

/**
 * Кнопка захвата фото (большая белая кнопка)
 */
@Composable
fun CaptureButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isCapturing: Boolean = false
) {
    Box(
        modifier = modifier
            .size(ComponentSizes.captureButtonSize)
            .clip(RoundedCornerShape(Roundings.xl))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        AppColors.White20,
                        AppColors.White20
                    )
                )
            )
            .border(
                width = 2.dp,
                color = AppColors.White40,
                shape = RoundedCornerShape(Roundings.xl)
            )
            .clickable(enabled = !isCapturing) { onClick() }
            .padding(4.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(Roundings.l))
                .background(if (isCapturing) AppColors.White40 else AppColors.White)
        )
    }
}

/**
 * Функциональная кнопка (переключение камеры, загрузка и т.д.)
 */
@Composable
fun FunctionButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Box(
        modifier = modifier
            .size(ComponentSizes.buttonSmallHeight)
            .clip(RoundedCornerShape(Roundings.l))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        AppColors.White20,
                        AppColors.White20
                    )
                )
            )
            .clickable(enabled = enabled) { onClick() }
            .padding(Spacing.l),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (enabled) AppColors.White else AppColors.White40,
            modifier = Modifier.size(ComponentSizes.iconLarge)
        )
    }
}

/**
 * Кнопка выбора эффекта
 */
@Composable
fun EffectButton(
    effectName: String,
    icon: ImageVector,
    isSelected: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(
                width = ComponentSizes.effectButtonWidth,
                height = ComponentSizes.effectButtonHeight
            )
            .clip(RoundedCornerShape(Roundings.m))
            .background(
                if (isSelected) AppColors.White20 else AppColors.MainGrey
            )
            .clickable { onClick() }
            .padding(Spacing.m),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.xs)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = effectName,
                tint = AppColors.White,
                modifier = Modifier.size(ComponentSizes.iconSmall)
            )
            Text(
                text = effectName,
                style = AppTypography.body1,
                color = AppColors.White,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }
    }
}

/**
 * Кнопка настройки параметра эффекта
 */
@Composable
fun SettingButton(
    paramName: String,
    icon: ImageVector,
    value: Int, // 0..100
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .height(ComponentSizes.settingButtonHeight)
            .clip(RoundedCornerShape(Roundings.m))
            .background(AppColors.MainGrey)
            .clickable { onClick() }
    ) {
        // Прогресс-индикатор (если значение > 0)
        if (value > 0) {
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(value / 100f)
                    .background(
                        AppColors.White20,
                        RoundedCornerShape(Roundings.m)
                    )
            )
        }
        
        // Содержимое кнопки
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(Spacing.m),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.xs)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = paramName,
                tint = AppColors.White,
                modifier = Modifier.size(ComponentSizes.iconSmall)
            )
            Text(
                text = paramName,
                style = AppTypography.body1,
                color = AppColors.White,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }
    }
}

/**
 * Кнопка выбора цвета
 */
@Composable
fun ColorButton(
    colorName: String,
    selectedColor: Color?,
    isGradient: Boolean = false,
    isEnabled: Boolean = true,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .height(ComponentSizes.settingButtonHeight)
            .clip(RoundedCornerShape(Roundings.m))
            .background(AppColors.MainGrey)
            .clickable(enabled = isEnabled) { onClick() }
            .padding(Spacing.m),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.xs)
        ) {
            // Иконка цвета
            Box(
                modifier = Modifier
                    .size(ComponentSizes.iconMedium)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = if (isEnabled) AppColors.White else AppColors.White20,
                        shape = CircleShape
                    )
                    .background(
                        selectedColor ?: AppColors.White,
                        CircleShape
                    )
            )
            
            Text(
                text = colorName,
                style = AppTypography.body1,
                color = if (isEnabled) AppColors.White else AppColors.White40,
                textAlign = TextAlign.Center,
                maxLines = 2
            )
        }
    }
}
