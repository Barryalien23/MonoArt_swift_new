package com.digitalreality.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import com.digitalreality.data.models.EffectType
import com.digitalreality.ui.theme.*

/**
 * Компонент выбора эффекта
 * Горизонтальный скролл со списком эффектов
 */
@Composable
fun EffectPicker(
    currentEffect: EffectType,
    effects: List<EffectType>,
    onEffectSelected: (EffectType) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .padding(Spacing.l),
        verticalArrangement = Arrangement.spacedBy(Spacing.l)
    ) {
        // Заголовок с кнопкой назад
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "ВЫБЕРИТЕ ЭФФЕКТ",
                style = AppTypography.head1,
                color = AppColors.White
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
        
        // Список эффектов
        LazyRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.s),
            contentPadding = PaddingValues(horizontal = Spacing.s)
        ) {
            items(effects) { effect ->
                EffectButton(
                    effectName = effect.displayName,
                    icon = ImageVector.vectorResource(effect.iconRes),
                    isSelected = effect == currentEffect,
                    onClick = { onEffectSelected(effect) }
                )
            }
        }
    }
}

/**
 * Компактный компонент текущего эффекта для главного экрана
 */
@Composable
fun CurrentEffectDisplay(
    effect: EffectType,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    EffectButton(
        effectName = effect.displayName,
        icon = ImageVector.vectorResource(effect.iconRes),
        isSelected = true,
        onClick = onClick,
        modifier = modifier
    )
}
