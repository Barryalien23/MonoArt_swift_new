package com.digitalreality.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import com.digitalreality.ui.theme.*

/**
 * Слайдер для настройки параметров эффекта
 */
@Composable
fun EffectParameterSlider(
    paramName: String,
    icon: ImageVector,
    value: Int, // 0..100
    onValueChange: (Int) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(
                AppColors.Black,
                RoundedCornerShape(topStart = Roundings.l, topEnd = Roundings.l)
            )
            .padding(Spacing.l),
        verticalArrangement = Arrangement.spacedBy(Spacing.l)
    ) {
        // Заголовок с иконкой параметра
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.s),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = paramName,
                tint = AppColors.White,
                modifier = Modifier.size(ComponentSizes.iconLarge)
            )
            Text(
                text = paramName.uppercase(),
                style = AppTypography.head1,
                color = AppColors.White,
                modifier = Modifier.weight(1f)
            )
            IconButton(
                onClick = onBackClick
            ) {
                Icon(
                    imageVector = ImageVector.vectorResource(R.drawable.ic_arrow_back),
                    contentDescription = "Back",
                    tint = AppColors.White
                )
            }
        }
        
        // Слайдер с отображением значения
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.l),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Значение слева
            Box(
                modifier = Modifier
                    .width(48.dp)
                    .height(40.dp)
                    .clip(RoundedCornerShape(Roundings.s))
                    .background(AppColors.MainGrey),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = value.toString(),
                    style = AppTypography.body2,
                    color = AppColors.White
                )
            }
            
            // Слайдер
            Slider(
                value = value.toFloat(),
                onValueChange = { onValueChange(it.toInt()) },
                valueRange = 0f..100f,
                modifier = Modifier.weight(1f),
                colors = SliderDefaults.colors(
                    thumbColor = AppColors.White,
                    activeTrackColor = AppColors.White,
                    inactiveTrackColor = AppColors.White20
                )
            )
        }
    }
}
