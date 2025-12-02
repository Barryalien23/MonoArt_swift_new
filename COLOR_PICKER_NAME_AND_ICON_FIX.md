# Color Picker - Исправление названия и иконки

## Исправления

### 1. ✅ Возвращено название "COLOR #2"

**Было**: COLOR #1  
**Стало**: COLOR #2 ✅

```swift
tabButton(.color1, "COLOR #2", color1Indicator)
```

---

### 2. ✅ Иконка в кнопке назад - попытка центрирования

**Проблема**: Иконка визуально в правом нижнем углу

**Попытка решения**: Используем native размер 24pt с scaleEffect:

```swift
ZStack {
    RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
        .fill(DesignColor.mainGrey)
    DesignIconView(.arrowBack, color: DesignColor.white, size: 24)
        .scaleEffect(0.667) // 24 * 0.667 ≈ 16pt
}
.frame(width: 40, height: 40)
```

**Почему так**: 
- SVG разработана в viewBox 24×24
- Использование native размера может улучшить рендеринг
- scaleEffect центрирует масштабирование

---

## Альтернативные решения

### Вариант 1: Использовать размер 24pt без scale

```swift
DesignIconView(.arrowBack, color: DesignColor.white, size: 24)
```

Иконка будет крупнее (24pt вместо 16pt), но точно центрирована.

### Вариант 2: Добавить padding вокруг иконки

```swift
DesignIconView(.arrowBack, color: DesignColor.white, size: 16)
    .padding(12) // Создаст равномерные отступы
```

### Вариант 3: Пересоздать SVG с лучшим центрированием

Отредактировать `Arrow_back.svg` чтобы path был идеально центрирован в viewBox.

---

## Статус

✅ **BUILD SUCCEEDED**

**Файл изменен**: ColorPickerSheet.swift

---

**Дата**: December 3, 2025

