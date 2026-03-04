# Guía de Compilación

## Realidad sobre compilar iOS desde Windows

### ❌ Lo que NO es posible
No existe toolchain para compilar apps iOS en Windows. El compilador Swift en Windows
solo genera binarios para Windows/Linux. Para iOS se necesita:

- SDK de iOS (solo en macOS)
- `ld64` (linker de Apple)
- `codesign` (firma de binarios)
- `xcodebuild` o `xcrun`
- Frameworks de iOS (UIKit, SwiftUI, AppIntents, etc.)

### ✅ Lo que SÍ puedes hacer en Windows
1. **Escribir todo el código** en VS Code (ya hecho)
2. **Editar y mantener** el proyecto con Copilot
3. **Preparar todo** excepto el paso de compilación

---

## Opción 1: Acceso temporal a un Mac (RECOMENDADA)

Solo necesitas ~30 minutos con un Mac para compilar.

### Requisitos en el Mac
- macOS 13+ (Ventura o posterior)
- Xcode 15+ instalado (descarga gratuita desde App Store)
- Homebrew instalado: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Pasos de compilación

#### 1. Clonar/copiar el proyecto al Mac
```bash
# Si tienes git
git clone <tu-repositorio> ~/Desktop/google-shortcuts
cd ~/Desktop/google-shortcuts

# O simplemente copia la carpeta via USB/Cloud
```

#### 2. Instalar XcodeGen
```bash
brew install xcodegen
```

#### 3. Generar el proyecto Xcode
```bash
cd ~/Desktop/google-shortcuts
xcodegen generate
```
Esto crea `GoogleShortcuts.xcodeproj` a partir de `project.yml`.

#### 4. Abrir en Xcode
```bash
open GoogleShortcuts.xcodeproj
```

#### 5. Configurar firma
1. En Xcode, selecciona el target **GoogleShortcuts**
2. Pestaña **Signing & Capabilities**
3. Marca **"Automatically manage signing"**
4. En **Team**, selecciona tu **Apple ID personal**
   - Si no aparece: Xcode > Settings > Accounts > "+" > Apple ID
5. Xcode generará automáticamente un provisioning profile gratuito

#### 6. Compilar para dispositivo (NO simulador)
```bash
# Conecta tu iPhone al Mac via cable USB

# Compilar para dispositivo
xcodebuild -project GoogleShortcuts.xcodeproj \
  -scheme GoogleShortcuts \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -archivePath build/GoogleShortcuts.xcarchive \
  archive \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic

# Exportar .ipa
xcodebuild -exportArchive \
  -archivePath build/GoogleShortcuts.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

#### 7. Crear ExportOptions.plist (necesario para exportar)
```bash
cat > ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
```

#### 8. Alternativa: Compilar directamente al iPhone conectado
Si tienes el iPhone conectado al Mac:
1. En Xcode, selecciona tu iPhone como destino (arriba)
2. Clic en ▶️ (Run)
3. La app se instala directamente en el iPhone
4. **Primera vez**: En el iPhone: Ajustes > General > VPN y Gestión de dispositivos > Confiar en tu Apple ID

---

## Opción 2: Mac en la nube (pago por hora)

Si no tienes acceso a un Mac físico:

### MacStadium / AWS EC2 Mac
- ~$1-2/hora
- macOS real en la nube
- SSH + VNC para acceder
- Instalar Xcode, compilar, descargar .ipa

### Pasos:
1. Crear instancia Mac en AWS EC2 o MacStadium
2. Conectar via VNC/SSH
3. Instalar Xcode (puede tardar ~1h la primera vez)
4. Seguir los pasos de la Opción 1
5. Descargar el .ipa resultante
6. Terminar la instancia

---

## Opción 3: macOS en VM (zona gris)

> ⚠️ Esto viola el EULA de Apple si se ejecuta en hardware no-Apple.
> Para uso personal/educativo, es una opción que existe.

### Con VMware/VirtualBox:
1. Necesitas una imagen de macOS (se puede crear desde un Mac o descargar)
2. Instalar macOS en VM
3. Instalar Xcode en la VM
4. Compilar normalmente

### Rendimiento:
- Sin GPU passthrough: Lento pero funcional para compilar
- Xcode funciona correctamente para compilación por terminal
- No necesitas el IDE gráfico, solo `xcodebuild`

---

## Generar .ipa sin Xcode (alternativa avanzada)

Si consigues acceso a un Mac pero sin Xcode completo instalado:

### Usando solo Command Line Tools
```bash
# Instalar solo las herramientas de línea de comandos
xcode-select --install

# NOTA: Esto NO incluye el SDK de iOS completo
# Necesitas Xcode completo para iOS
```

### Usando Swift Package Manager (limitado)
SPM no soporta generar .ipa para iOS. Solo funciona para:
- macOS CLI apps
- Libraries/frameworks
- NO para apps iOS con SwiftUI/App Intents

---

## Estructura de archivos generados

Después de compilar:
```
build/
├── GoogleShortcuts.xcarchive/     # Archivo compilado
│   └── Products/
│       └── Applications/
│           └── GoogleShortcuts.app/
└── ipa/
    └── GoogleShortcuts.ipa        # ← Este archivo es el que necesitas
```

El `.ipa` es el que instalas con SideStore o LiveContainer.

---

## Script de compilación completo

Guarda este script para ejecutar en un Mac:

```bash
#!/bin/bash
set -e

echo "=== Compilando GoogleShortcuts ==="

# 1. Instalar dependencias
if ! command -v xcodegen &> /dev/null; then
    echo "Instalando XcodeGen..."
    brew install xcodegen
fi

# 2. Generar proyecto
echo "Generando proyecto Xcode..."
xcodegen generate

# 3. Crear ExportOptions
cat > ExportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
PLIST

# 4. Compilar
echo "Compilando..."
xcodebuild -project GoogleShortcuts.xcodeproj \
  -scheme GoogleShortcuts \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -archivePath build/GoogleShortcuts.xcarchive \
  archive \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="" \
  2>&1 | tail -5

# 5. Exportar IPA
echo "Exportando IPA..."
xcodebuild -exportArchive \
  -archivePath build/GoogleShortcuts.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa \
  2>&1 | tail -5

echo "=== ✅ IPA generado en build/ipa/GoogleShortcuts.ipa ==="
```

Guárdalo como `build.sh` y ejecútalo con:
```bash
chmod +x build.sh
./build.sh
```
