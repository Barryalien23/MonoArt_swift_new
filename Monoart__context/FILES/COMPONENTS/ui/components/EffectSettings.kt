package com.digitalreality.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import com.digitalreality.data.models.EffectParams
import com.digitalreality.ui.theme.*

/**
 * Параметры эффекта с иконками
 */
data class EffectParameter(
    val name: String,
    val icon: Int, // drawable resource
    val getValue: (EffectParams) -> Int,
    val displayName: String
)

val effectParameters = listOf(
    EffectParameter("Cell", R.drawable.ic_setting_cell, { it.cell }, "CELL"),
    EffectParameter("Jitter", R.drawable.ic_setting_jitter, { it.jitter }, "JITTER"),
    EffectParameter("Edje", R.drawable.ic_setting_edge, { it.edje }, "EDGE"),
    EffectParameter("Softy", R.drawable.ic_setting_softy, { it.softy }, "SOFTY")
)

/**
 * Экран настройки параметров эффекта
 */
@Composable
fun EffectSettingsScreen(
    params: EffectParams,
    selectedParam: String?,
    onParamSelected: (String) -> Unit,
    onParamValueChanged: (String, Int) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Верхняя панель с табами параметров
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Black)
                .padding(Spacing.l),
            horizontalArrangement = Arrangement.spacedBy(Spacing.s)
        ) {
            items(effectParameters) { param ->
                val isSelected = param.name == selectedParam
                val value = param.getValue(params)
                
                SettingButton(
                    paramName = param.displayName,
                    icon = ImageVector.vectorResource(param.icon),
                    value = value,
                    onClick = { onParamSelected(param.name) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
        
        // Слайдер для выбранного параметра
        selectedParam?.let { paramName ->
            val param = effectParameters.find { it.name == paramName }
            param?.let {
                val currentValue = param.getValue(params)
                EffectParameterSlider(
                    paramName = param.displayName,
                    icon = ImageVector.vectorResource(param.icon),
                    value = currentValue,
                    onValueChange = { newValue ->
                        onParamValueChanged(paramName, newValue)
                    },
                    onBackClick = onBackClick
                )
            }
        }
    }
}

/**
 * Компактная панель настроек для главного экрана
 */
@Composable
fun EffectSettingsPanel(
    params: EffectParams,
    onParamClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.s)
    ) {
        effectParameters.forEach { param ->
            val value = param.getValue(params)
            SettingButton(
                paramName = param.displayName,
                icon = ImageVector.vectorResource(param.icon),
                value = value,
                onClick = { onParamClick(param.name) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}
