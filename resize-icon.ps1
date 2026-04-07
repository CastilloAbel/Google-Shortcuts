#!/usr/bin/env pwsh
# Script para redimensionar icono PNG a todos los tamaños requeridos para iOS
# Requiere ImageMagick instalado: https://imagemagick.org/script/download.php#windows
#
# Uso:
# .\resize-icon.ps1 -IconPath "C:\ruta\a\tu\icono.png" -OutputDir "GoogleShortcuts\Assets.xcassets\AppIcon.appiconset"
#
# O simplemente:
# .\resize-icon.ps1
# Y luego selecciona el archivo cuando se pida

param(
    [string]$IconPath = "",
    [string]$OutputDir = ""
)

# Si no se proporciona path, pedir al usuario
if (-not $IconPath) {
    Write-Host "[RESIZE ICON - iOS]" -ForegroundColor Cyan
    Write-Host "Selecciona tu archivo PNG de icono (minimo 1024x1024)..."
    Write-Host ""
    
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "PNG Files (*.png)|*.png|All Files (*.*)|*.*"
    $dialog.Title = "Selecciona tu icono PNG"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $IconPath = $dialog.FileName
        Write-Host "[OK] Archivo seleccionado: $IconPath" -ForegroundColor Green
    } else {
        Write-Host "[ABORTADO] Cancelado por el usuario" -ForegroundColor Red
        exit 1
    }
}

if (-not $OutputDir) {
    $OutputDir = "GoogleShortcuts\Assets.xcassets\AppIcon.appiconset"
}

# Verificar que el archivo existe
if (-not (Test-Path $IconPath)) {
    Write-Host "[ERROR] No se encontro el archivo '$IconPath'" -ForegroundColor Red
    exit 1
}

# Verificar que Output dir existe
if (-not (Test-Path $OutputDir)) {
    Write-Host "[ERROR] Directorio de salida no existe: $OutputDir" -ForegroundColor Red
    exit 1
}

# Verificar ImageMagick
$magickFound = $false
try {
    $magickTest = magick -version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $magickFound = $true
    }
} catch { }

if (-not $magickFound) {
    Write-Host ""
    Write-Host "[ERROR] ImageMagick no esta instalado o no esta en el PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Descargalo e instalalo desde: https://imagemagick.org/script/download.php#windows"
    Write-Host ""
    Write-Host "O usa winget:"
    Write-Host "  winget install ImageMagick.ImageMagick"
    Write-Host ""
    exit 1
}

# Tamaños requeridos: (filename, size)
$sizes = @(
    @("iPhone-Notification-20@2x.png", "40x40"),
    @("iPhone-Notification-20@3x.png", "60x60"),
    @("iPhone-Settings-29@2x.png", "58x58"),
    @("iPhone-Settings-29@3x.png", "87x87"),
    @("iPhone-Spotlight-40@2x.png", "80x80"),
    @("iPhone-Spotlight-40@3x.png", "120x120"),
    @("iPhone-App-60@2x.png", "120x120"),
    @("iPhone-App-60@3x.png", "180x180"),
    @("iPad-Notification-20.png", "20x20"),
    @("iPad-Notification-20@2x.png", "40x40"),
    @("iPad-Settings-29.png", "29x29"),
    @("iPad-Settings-29@2x.png", "58x58"),
    @("iPad-Spotlight-40.png", "40x40"),
    @("iPad-Spotlight-40@2x.png", "80x80"),
    @("iPad-App-76.png", "76x76"),
    @("iPad-App-76@2x.png", "152x152"),
    @("iPad-Pro-App-83.5@2x.png", "167x167"),
    @("iPhone-App-Store-1024.png", "1024x1024")
)

Write-Host ""
Write-Host "[INICIANDO] Redimensionando icono a $($sizes.Count) variaciones..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($size in $sizes) {
    $filename = $size[0]
    $dimension = $size[1]
    $outputPath = Join-Path $OutputDir $filename
    
    Write-Host "  -> $filename ($dimension)..." -NoNewline
    
    try {
        magick "$IconPath" -resize "$dimension" -background none -gravity center -extent "$dimension" "$outputPath" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [OK]" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " [FALLO]" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host " [ERROR: $_]" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "[COMPLETADO] $successCount/$($sizes.Count) imagenes generadas" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "[ADVERTENCIA] $failCount imagenes fallaron. Verifica los errores arriba." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[EXITO] Iconos listos. Ahora puedes compilar la app en Xcode." -ForegroundColor Green
