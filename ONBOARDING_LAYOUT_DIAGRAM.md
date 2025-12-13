# Onboarding Layout Diagram

## 🔴 ТЕКУЩИЙ LAYOUT (Неправильный)

```
┌─────────────────────────────────┐
│                                 │
│         Spacer (142)            │  ← Лишнее пространство
│                                 │
├─────────────────────────────────┤
│    [Step Bar]                   │
│    padding.top(40)              │
├─────────────────────────────────┤
│                                 │
│      Color.clear                │
│      .frame(540)                │
│      .overlay(Video 682)        │  ← Видео в overlay
│                                 │
├─────────────────────────────────┤
│   [Text + Button Block]         │
│   - Title                       │
│   - Description                 │
│   - Button                      │
├─────────────────────────────────┤
│                                 │
│         Spacer()                │  ← Растягивается
│                                 │
└─────────────────────────────────┘
```

**Проблемы:**
- ❌ Spacer(142) создает пустое место сверху
- ❌ Видео не выходит за step bar
- ❌ Текстовый блок не прижат к низу
- ❌ Нет вертикального заполнения

---

## ✅ ОЖИДАЕМЫЙ LAYOUT (Правильный)

```
┌─────────────────────────────────┐
│ ╔═══════════════════════════╗   │  ← Safe Area (Dynamic Island)
│ ║  [Step Bar]               ║   │
│ ║  - Step Indicator         ║   │  ← Прижат к верху с safe area
│ ║  - Skip Button            ║   │
│ ╚═══════════════════════════╝   │
├─────────────────────────────────┤
│         ┌───────────┐           │
│         │           │           │
│         │           │           │  ← Видео ВЫХОДИТ за step bar
│         │           │           │     (верхняя часть ~142px)
│         │   VIDEO   │           │
│         │   682px   │           │
│         │           │           │
│         │  (visible │           │
│         │   540px)  │           │
│         │           │           │
│         │           │           │
│         └───────────┘           │
│                                 │  ← Video aligned bottom
├─────────────────────────────────┤
│ ╔═══════════════════════════╗   │
│ ║ [Text + Button Block]     ║   │
│ ║                           ║   │
│ ║ TITLE TEXT (16pt)         ║   │  ← Прижат к низу
│ ║ Description text (20pt)   ║   │
│ ║                           ║   │
│ ║   [Next Button]           ║   │
│ ╚═══════════════════════════╝   │
│                                 │  ← Safe Area (home indicator)
└─────────────────────────────────┘
```

**Требования:**
- ✅ Step bar прижат к верху с safe area
- ✅ Видео под step bar, выходит за края сверху (~142px)
- ✅ Видео выровнено по bottom
- ✅ Текстовый блок прижат к низу экрана
- ✅ Вертикальное заполнение (no gaps)

---

## 🎯 ПРАВИЛЬНАЯ СТРУКТУРА (ZStack + Alignment)

```swift
ZStack {
    // Black background + ASCII pattern

    VStack(spacing: 0) {
        // Step bar - pinned to top
        TopStepBar
            .padding(.top, safeAreaTop)
            .zIndex(3)

        Spacer() // ← Flexible space between step bar and bottom

        // Text + Button block - pinned to bottom
        VStack {
            Text (Title)
            Text (Description)
            Button
        }
        .zIndex(1)
    }

    // Video - centered with bottom alignment
    Video (682px)
        .offset(y: calculate_to_align_with_text_block)
        .zIndex(2)
}
```

---

## 📐 РАЗМЕРЫ

- **Step Bar**: ~44pt height + safe area top
- **Video**: 327×682pt (rounded 62px)
- **Video Container**: 540pt layout space
- **Video Overflow**: ~142pt extends beyond container
- **Text Block**: ~200pt height (variable)
- **Safe Area Top**: ~47pt (iPhone with Dynamic Island) / ~20pt (older)
- **Safe Area Bottom**: ~34pt (home indicator)

---

## 🔄 Z-INDEX СЛОИ

```
Layer 3 (top):    Step Bar
Layer 2 (middle): Video (682px)
Layer 1 (bottom): Text + Button Block
Layer 0 (base):   Background (black + ASCII pattern)
```

---

## ✏️ ТЕКСТ НА 4-М ЭКРАНЕ (Permission)

**ВАЖНО:** Текст УЖЕ правильный в `OnboardingState.swift`:

```swift
case .permissions:
    title: "Become a line of code"
    description: "Use 6+ ASCII art filters for avatars and wallpapers"
```

**Если видите старый текст:**
1. Clean Build: Product → Clean Build Folder (⌘⇧K)
2. Restart Xcode
3. Rebuild: ⌘B

---

## 🐛 DEBUG: Проверка текущего layout

Добавить в OnboardingVideoScreen:
```swift
.overlay(
    VStack {
        Text("Step Bar Zone")
            .frame(height: 100)
            .background(Color.red.opacity(0.3))
        Spacer()
        Text("Video Zone (540px)")
            .frame(height: 540)
            .background(Color.blue.opacity(0.3))
        Text("Text Zone")
            .frame(height: 200)
            .background(Color.green.opacity(0.3))
        Spacer()
    }
    .allowsHitTesting(false)
)
```
