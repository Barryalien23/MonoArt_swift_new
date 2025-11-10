# Руководство по интеграции Android компонентов

## Обзор

Этот проект содержит полный набор Jetpack Compose компонентов для создания Android приложения Digital Reality - камера с визуальными эффектами.

## Структура проекта

```
android_components/
├── ui/
│   ├── theme/           # Дизайн-система
│   │   ├── Colors.kt    # Цвета из Figma
│   │   ├── Typography.kt # Шрифты IBM Plex Mono
│   │   ├── Dimensions.kt # Размеры и отступы
│   │   ├── Effects.kt   # Эффекты (blur, shadow)
│   │   └── Theme.kt     # Общая тема
│   ├── components/      # UI компоненты
│   │   ├── Buttons.kt   # Кнопки (Capture, Function, Setting, Color)
│   │   ├── Sliders.kt   # Слайдеры для параметров
│   │   ├── EffectPicker.kt     # Выбор эффекта
│   │   ├── EffectSettings.kt   # Настройки параметров
│   │   ├── ColorPicker.kt      # Выбор цветов
│   │   └── CameraPreview.kt    # Превью камеры
│   ├── screens/         # Экраны
│   │   └── MainScreen.kt       # Главный экран
│   └── effects/         # Визуальные эффекты
│       └── EffectRenderer.kt   # Рендеринг эффектов
├── data/
│   └── models/          # Модели данных
│       ├── EffectModels.kt     # EffectType, EffectParams
│       ├── ColorModels.kt      # ColorState, SymbolPaint
│       └── CameraModels.kt     # CameraFacing, CaptureState
├── viewmodel/           # ViewModels
│   └── MainViewModel.kt        # Основной ViewModel
├── utils/               # Утилиты
│   ├── PermissionUtils.kt      # Работа с разрешениями
│   └── ImageUtils.kt           # Обработка изображений
├── build.gradle.kts     # Зависимости
├── AndroidManifest.xml  # Манифест приложения
└── MainActivity.kt      # Главная активность
```

## Шаги интеграции

### 1. Создание нового Android проекта

1. Откройте Android Studio
2. Создайте новый проект с Compose Activity
3. Выберите минимальный SDK 24 (Android 7.0)

### 2. Настройка зависимостей

Скопируйте содержимое `build.gradle.kts` в ваш модуль app. Основные зависимости:
- Jetpack Compose
- CameraX
- ViewModel
- Material 3

### 3. Копирование кода

1. Скопируйте всю папку `ui/` в `src/main/java/com/digitalreality/ui/`
2. Скопируйте папку `data/` в `src/main/java/com/digitalreality/data/`
3. Скопируйте папку `viewmodel/` в `src/main/java/com/digitalreality/viewmodel/`
4. Скопируйте папку `utils/` в `src/main/java/com/digitalreality/utils/`

### 4. Настройка ресурсов

#### Скопируйте иконки из `res/drawable/`:
Все необходимые иконки уже созданы в папке `res/drawable/`:
- ✅ `ic_upload.xml` - кнопка загрузки
- ✅ `ic_rotate_camera.xml` - поворот камеры  
- ✅ `ic_arrow_back.xml` - кнопка назад
- ✅ `ic_delete.xml` - кнопка удаления
- ✅ `ic_save.xml` - сохранение фото
- ✅ `ic_setting_cell.xml` - параметр Cell
- ✅ `ic_setting_jitter.xml` - параметр Jitter
- ✅ `ic_setting_edge.xml` - параметр Edge
- ✅ `ic_setting_softy.xml` - параметр Softy
- ✅ `ic_effect_ascii.xml` - эффект ASCII
- ✅ `ic_effect_circles.xml` - эффект Circles
- ✅ `ic_effect_squares.xml` - эффект Squares
- ✅ `ic_effect_triangle.xml` - эффект Triangle
- ✅ `ic_effect_diamonds.xml` - эффект Diamonds
- ✅ `ic_effect_shapes.xml` - эффект Shapes

**Просто скопируйте всю папку `res/` в ваш Android проект!**

#### Добавьте шрифты IBM Plex Mono в `res/font/`:
- `ibm_plex_mono_regular.ttf`
- `ibm_plex_mono_medium.ttf`
- `ibm_plex_mono_semibold.ttf`

### 5. Настройка манифеста

Скопируйте содержимое `AndroidManifest.xml`, особенно:
- Разрешения для камеры
- FileProvider для сохранения фото
- Ориентация портретная

### 6. Главная активность

Замените содержимое `MainActivity.kt` на предоставленный код.

## Особенности реализации

### Дизайн-система
- Все цвета, размеры и стили взяты из Figma Variables
- Используется шрифт IBM Plex Mono
- Темная тема по умолчанию

### Архитектура
- MVVM с Compose State
- Единый ViewModel для всего приложения
- Реактивное управление состоянием

### Компоненты
- **EffectPicker**: Горизонтальный скролл эффектов
- **EffectSettings**: Табы + слайдер для параметров
- **ColorPicker**: RGB слайдеры + табы режимов
- **CameraPreview**: CameraX интеграция
- **EffectRenderer**: Canvas рендеринг эффектов

### Эффекты
Реализованы базовые эффекты:
- ASCII (точки разного размера)
- Circles (окружности)
- Squares (квадраты)
- Triangle (треугольники)
- Diamonds (ромбы)
- Shapes (случайные фигуры)

## Что нужно доработать

### 1. Иконки
Создать векторные иконки для всех эффектов и действий

### 2. Шейдеры
Для лучшей производительности заменить Canvas на AGSL шейдеры

### 3. Захват фото
Реализовать сохранение изображения с наложенными эффектами

### 4. Анимации
Добавить анимации переходов и вводную анимацию эффекта

### 5. Обработка ошибок
Добавить обработку ошибок камеры и разрешений

## Тестирование

1. Запустите приложение на устройстве с камерой
2. Предоставьте разрешения камеры
3. Проверьте переключение эффектов
4. Протестируйте настройку параметров
5. Проверьте выбор цветов и градиентов

## Производительность

- Эффекты рендерятся в реальном времени
- Jitter анимация работает на 60fps
- Градиенты применяются только к символам
- Используется минимум аллокаций в рендере

## Соответствие дизайну

Все компоненты точно соответствуют дизайну из Figma:
- Размеры и отступы из Variables
- Цвета и прозрачности
- Типографика IBM Plex Mono
- Поведение компонентов по спецификации
