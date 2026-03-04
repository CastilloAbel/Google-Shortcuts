#!/bin/bash
# build.sh - Script de compilación para GoogleShortcuts
# Ejecutar en macOS con Xcode instalado
set -e

echo "=========================================="
echo "  GoogleShortcuts - Build Script"
echo "=========================================="

# Verificar que estamos en macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Este script debe ejecutarse en macOS"
    exit 1
fi

# Verificar Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode no está instalado"
    echo "   Instala Xcode desde la App Store"
    exit 1
fi

echo "✅ macOS detectado"
echo "✅ Xcode encontrado: $(xcodebuild -version | head -1)"

# 1. Instalar XcodeGen si no existe
if ! command -v xcodegen &> /dev/null; then
    echo ""
    echo "📦 Instalando XcodeGen..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "❌ Homebrew no encontrado. Instala Homebrew primero:"
        echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
fi

echo "✅ XcodeGen encontrado"

# 2. Verificar que OAuthConfig tiene un Client ID real
if grep -q "YOUR_CLIENT_ID" GoogleShortcuts/Core/Auth/OAuthConfig.swift 2>/dev/null; then
    echo ""
    echo "⚠️  ADVERTENCIA: No has configurado tu Client ID de Google."
    echo "   Edita: GoogleShortcuts/Core/Auth/OAuthConfig.swift"
    echo "   Reemplaza YOUR_CLIENT_ID con tu Client ID real."
    echo ""
    read -p "¿Continuar de todos modos? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# 3. Generar proyecto Xcode
echo ""
echo "🔧 Generando proyecto Xcode..."
xcodegen generate
echo "✅ GoogleShortcuts.xcodeproj generado"

# 4. Crear ExportOptions.plist
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

# 5. Limpiar build anterior
echo ""
echo "🧹 Limpiando builds anteriores..."
rm -rf build/
mkdir -p build

# 6. Compilar
echo ""
echo "🏗️  Compilando... (esto puede tardar unos minutos)"
xcodebuild -project GoogleShortcuts.xcodeproj \
  -scheme GoogleShortcuts \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -archivePath build/GoogleShortcuts.xcarchive \
  archive \
  CODE_SIGN_IDENTITY="Apple Development" \
  CODE_SIGN_STYLE=Automatic \
  2>&1 | grep -E '(error:|warning:|BUILD|archive)' || true

# Verificar que el archive se creó
if [ ! -d "build/GoogleShortcuts.xcarchive" ]; then
    echo "❌ Error en la compilación. Revisa los errores arriba."
    echo ""
    echo "Posibles soluciones:"
    echo "1. Abre GoogleShortcuts.xcodeproj en Xcode"
    echo "2. Configura tu Apple ID en Signing & Capabilities"
    echo "3. Selecciona un Team válido"
    echo "4. Compila desde Xcode directamente (Cmd+B)"
    exit 1
fi

echo "✅ Compilación exitosa"

# 7. Exportar IPA
echo ""
echo "📦 Exportando IPA..."
xcodebuild -exportArchive \
  -archivePath build/GoogleShortcuts.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa \
  2>&1 | grep -E '(error:|EXPORT|ipa)' || true

if [ -f "build/ipa/GoogleShortcuts.ipa" ]; then
    echo ""
    echo "=========================================="
    echo "  ✅ BUILD COMPLETADO"
    echo "=========================================="
    echo ""
    echo "  📱 IPA: build/ipa/GoogleShortcuts.ipa"
    echo ""
    echo "  Siguiente paso:"
    echo "  1. Transfiere el .ipa a tu iPhone"
    echo "  2. Instala con SideStore o LiveContainer"
    echo "  3. Ver: docs/SIDELOAD_GUIDE.md"
    echo ""
else
    echo ""
    echo "⚠️  No se pudo exportar el IPA automáticamente."
    echo "    Intenta compilar desde Xcode directamente:"
    echo "    1. open GoogleShortcuts.xcodeproj"
    echo "    2. Product > Archive"
    echo "    3. Distribute App > Development"
    echo ""
fi

# Limpiar
rm -f ExportOptions.plist
