# ✅ Guía: Agregar Icono + Liquid Glass Effect

## 1️⃣ Agregar tu Icono PNG

### Paso 1: Descargar ImageMagick (Windows)
Tu imagen PNG debe ser **mínimo 1024x1024 píxeles** en alta resolución.

Descarga e instala:
- **ImageMagick**: [https://imagemagick.org/script/download.php#windows](https://imagemagick.org/script/download.php#windows)
  - Durante la instalación: ✅ Marca "Add ImageMagick to system PATH"
  - ✅ "Install development headers and libraries"

### Paso 2: Ejecutar el Script de Redimensionamiento

Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
.\resize-icon.ps1
```

El script te pedirá seleccionar tu PNG. Luego:
- Redimensionará automáticamente a 18 tamaños diferentes
- Guardará todas las imágenes en `GoogleShortcuts/Assets.xcassets/AppIcon.appiconset/`
- Xcode las detectará automáticamente

### Paso 3: Compilar en Xcode
Una vez redimensionadas:
```bash
cd /path/to/proyecto  # macOS
xcodegen generate
xcode build  # o abrir en Xcode
```

✅ **El icono aparecerá en la pantalla de inicio de tu iPhone**

---

## 2️⃣ Liquid Glass Effect (Automático)

### ¿Qué es?
Efecto de vidrio esmerilado que cambia automáticamente según el tema:
- 💡 **Light Mode**: Vidrio claro y transparent
- 🌙 **Dark Mode**: Vidrio oscuro y tenue

### Ya está implementado! 

El archivo `GoogleShortcuts/UI/GlassEffect.swift` contiene:

```swift
// Modifier simple
struct GlassEffect: ViewModifier { ... }

// Uso en cualquier View:
VStack { ... }
    .glassEffect()
```

### Ejemplo en ContentView.swift

Para envolver tu vista en glass effect:

```swift
VStack(spacing: 20) {
    // Tu contenido aquí
    VStack {
        Image(systemName: "envelope.fill")
        Text("Correos")
    }
    .glassEffect()  // ✨ Aplicar el efecto
}
```

### Versión avanzada (colores personalizados)

```swift
VStack { ... }
    .glassEffect(lightColor: .blue, darkColor: .cyan, blur: 15)
```

**Parámetros:**
- `lightColor`: Color para Light Mode (default: `.white`)
- `darkColor`: Color para Dark Mode (default: `.black`)
- `blur`: Intensidad del blur (default: `10`)

---

## 3️⃣ Vista Previa en Xcode

Puedes ver el GlassEffect en diferentes modos:

```swift
#Preview {
    GlassEffectExample()
        .preferredColorScheme(.light)  // Light mode
}

#Preview("Dark Mode") {
    GlassEffectExample()
        .preferredColorScheme(.dark)   // Dark mode
}
```

---

## 📝 Resumen de Cambios

### ✅ Archivos Creados
```
GoogleShortcuts/
├── Assets.xcassets/
│   └── AppIcon.appiconset/
│       ├── Contents.json  (configuración)
│       └── [18 imágenes PNG redimensionadas]
│
└── UI/
    └── GlassEffect.swift  (modifier de vidrio)

resize-icon.ps1  (script automatizado)
```

### 🎨 Cómo se ve

**Light Mode:**
```
┌─────────────────────────┐
│  ✨ Liquid Glass        │
│  Vidrio claro          │
│  + Blur suave          │
└─────────────────────────┘
```

**Dark Mode:**
```
┌─────────────────────────┐
│  ✨ Liquid Glass        │
│  Vidrio oscuro         │
│  + Blur más intenso    │
└─────────────────────────┘
```

---

## 🔧 Solución de Problemas

### Q: "ImageMagick no se encuentra"
**A:** 
1. Instálalo desde [imagemagick.org](https://imagemagick.org)
2. Marca "Add to PATH" durante la instalación
3. Reinicia PowerShell
4. Intenta de nuevo

### Q: "Mi imagen sale distorsionada"
**A:** El script usa `-extent` para rellenar, pero:
- Si tu imagen es cuadrada (1024x1024), será perfecta
- iOS luego lo redondeará según necesite

### Q: "¿Puedo cambiar el color del glass effect?"
**A:** Sí! En `GlassEffect.swift`:

```swift
// Light Mode (línea ~20)
Color.white.opacity(0.3)  // ← Cambia aquí (0-1)

// Dark Mode (línea ~18)
Color.black.opacity(0.15)  // ← O aquí
```

O usa la versión avanzada:
```swift
.glassEffect(lightColor: .blue, darkColor: .purple)
```

---

## 📱 Testear en iPhone

Una vez compilado:
1. Sideload en tu iPhone 13 via SideStore
2. El icono debería aparecer en pantalla de inicio
3. Cambiar Dark/Light Mode (Ajustes → Pantalla) 
4. Ver cómo cambia el glass effect en la app

---

## ⚠️ Notas Importantes

- El icono **NO necesita entitlements** pagos en Apple (es solo UI)
- El glass effect funciona en **iOS 15+** (tu app requiere iOS 16)
- En el App Store, la imagen marketing de 1024x1024 se usa automáticamente
- Xcode puede cachear Assets - si no ves cambios: **Product → Clean Build Folder**

---

## ✨ Próximos Pasos

Una vez agregado el icono:
1. Ejecuta `git add -A && git commit -m "feat: add app icon and liquid glass effect"`
2. Push a Codemagic
3. Verifica en la compilación que Xcode detecte `Assets.xcassets`
4. Descarga el .ipa y prueba en iPhone 13

¡Listo! 🎉
