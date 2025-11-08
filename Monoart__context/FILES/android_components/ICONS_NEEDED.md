# Список необходимых иконок для Android приложения

## Иконки действий (24dp)

### `ic_upload.xml`
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"/>
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,11L16,15H13V19H11V15H8L12,11Z"/>
</vector>
```

### `ic_rotate_camera.xml`
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,2A10,10 0 0,1 22,12A10,10 0 0,1 12,22A10,10 0 0,1 2,12A10,10 0 0,1 12,2M12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20A8,8 0 0,0 20,12A8,8 0 0,0 12,4M12,6L16,10H13V14H11V10H8L12,6Z"/>
</vector>
```

## Альтернатива

Если у вас есть SVG иконки из Figma, используйте Vector Asset Studio в Android Studio:
1. Right-click на `res/drawable/`
2. New → Vector Asset
3. Asset Type: Local file (SVG)
4. Выберите SVG файл из Figma
5. Настройте размер и цвет
