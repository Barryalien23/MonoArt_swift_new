# Android Components для Digital Reality

Этот раздел содержит все компоненты Jetpack Compose для создания нативного Android приложения.

## Структура проекта

```
android_components/
├── ui/
│   ├── theme/           # Дизайн-система (цвета, типографика, размеры)
│   ├── components/      # Переиспользуемые UI компоненты
│   ├── screens/         # Экраны приложения
│   └── effects/         # Визуальные эффекты и шейдеры
├── data/
│   ├── models/          # Модели данных (EffectType, ColorState и т.д.)
│   └── repositories/    # Репозитории для управления состоянием
├── viewmodel/           # ViewModels для экранов
└── utils/               # Утилиты и расширения
```

## Основные компоненты

1. **MainScreen** - главный экран с камерой и настройками
2. **EffectPicker** - выбор визуального эффекта  
3. **EffectSettings** - настройка параметров эффекта
4. **ColorPicker** - выбор цветов и градиентов
5. **CameraPreview** - превью камеры с CameraX
6. **EffectRenderer** - рендеринг эффектов поверх камеры

## Технические требования

- **Язык**: Kotlin
- **UI**: Jetpack Compose
- **Архитектура**: MVVM с State/ViewModel
- **Камера**: CameraX с PreviewView
- **Эффекты**: AGSL Shaders или Compose Canvas
- **Шрифт**: IBM Plex Mono

## Дизайн-система

Все размеры, цвета и стили взяты из Figma Variables и соответствуют дизайну.
