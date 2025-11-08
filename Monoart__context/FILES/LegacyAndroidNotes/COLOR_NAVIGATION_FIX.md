# Исправление навигации по цветам ✅

## Проблема:
Все кнопки цветов (BG COLOR, COLOR #1, GRADIENT) на главном экране открывали один экран Color Picker с табом "Background", независимо от того, на какую кнопку нажал пользователь.

## Решение:

### 1. **MainSettingsPanel.kt** - Разделили обработчики
```kotlin
// Было:
onColorClick: () -> Unit

// Стало:
onBackgroundColorClick: () -> Unit,
onSymbolColorClick: () -> Unit,
onGradientClick: () -> Unit
```

### 2. **MainViewModel.kt** - Добавили функцию навигации
```kotlin
fun navigateToColorPicker(colorType: String) {
    _selectedEffectParam.value = colorType
    _currentScreen.value = Screen.COLOR_PICKER
}
```

### 3. **MainScreen.kt** - Передаем правильные обработчики
```kotlin
onBackgroundColorClick = { viewModel.navigateToColorPicker("background") },
onSymbolColorClick = { viewModel.navigateToColorPicker("symbols") },
onGradientClick = { viewModel.navigateToColorPicker("gradient") }
```

### 4. **ColorPickerBlockScreen** - Используем переданный параметр
```kotlin
val initialTab = when (selectedColorType) {
    "background" -> ColorTab.BACKGROUND
    "symbols" -> ColorTab.COLOR1
    "gradient" -> ColorTab.GRADIENT
    else -> ColorTab.BACKGROUND
}
```

## Результат:

### ✅ **Теперь работает правильно:**
- **BG COLOR** → открывает Color Picker с табом **"Background"**
- **COLOR #1** → открывает Color Picker с табом **"COLOR #1"**  
- **GRADIENT** → открывает Color Picker с табом **"GRADIENT"**

### 🎯 **Пользователь попадает именно туда, куда нажал!**

---

**Linter**: ✅ Нет ошибок  
**Компиляция**: ✅ Готово  
**Функциональность**: ✅ Навигация работает правильно  

🚀 **Проблема решена!**
