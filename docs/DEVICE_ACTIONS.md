# 🎯 Device Actions - Guía Completa

## 📱 ¿Qué son Device Actions?

Device Actions es un **conjunto de 20+ acciones** que exponen información y estado del dispositivo iOS desde la app de Atajos (Shortcuts). Similar a la app "Actions" de Sindre Sorhus, pero integrada directamente en tu app de Gmail Shortcuts.

Son acciones que **NO requieren autenticación con Google** y están disponibles **sin conexión a internet**.

---

## ✨ Acciones Disponibles

### 🔋 Batería & Poder

| Acción | Descripción | Devolución | Ejemplo |
|--------|-------------|-----------|---------|
| **Nivel de Batería** | Obtiene el porcentaje actual | 0-100 (int) | "Mi batería es 73%" |
| **¿Batería Baja?** | Verifica si está bajo un umbral (default: 20%) | true/false (bool) | true si < 20% |
| **Estado de Batería** | Estado: charging, full, unplugged | "charging" / "full" / "unplugged" | Saber si está cargando |
| **¿Modo Bajo Consumo?** | Si está activado Ahorro de Energía | true/false (bool) | true si Low Power Mode ON |

### 📡 Conectividad

| Acción | Descripción | Devolución | Nota |
|--------|-------------|-----------|------|
| **¿Bluetooth?** | Si Bluetooth está activo | true/false | Requiere CBCentralManager |
| **¿WiFi?** | Si está conectado a WiFi | true/false | Usa NWPathMonitor |
| **¿VPN?** | Si hay VPN activa | true/false | Usa NEVPNManager |
| **¿Datos Móviles?** | Si datos celulares están ON | true/false | Usa CTCellularData |

### 📱 Dispositivo & Info

| Acción | Descripción | Devolución | Ejemplo |
|--------|-------------|-----------|---------|
| **Modelo del Dispositivo** | Nombre del dispositivo | "iPhone 15 Pro" / "iPhone 13" | Mapeo de códigos a nombres |
| **Nombre del Dispositivo** | Nombre personalizado que diste | "iPhone de Abel" | De UIDevice.current.name |
| **Versión de iOS** | Versión del SO | "16.4.1" / "17.2" | De UIDevice.current.systemVersion |

### 🌐 Red & Internet

| Acción | Descripción | Devolución | Ejemplo |
|--------|-------------|-----------|---------|
| **¿Online?** | Si hay conexión a internet | true/false | Uso NWPathMonitor |
| **Tipo de Conexión** | WiFi, Cellular, u Offline | "wifi" / "cellular" / "unavailable" | Útil para atajos condicionales |

### 💾 Almacenamiento & Pantalla

| Acción | Descripción | Devolución | Unidad |
|--------|-------------|-----------|--------|
| **Espacio Disponible** | Almacenamiento libre | número en GB | ej: 45.2 GB |
| **Almacenamiento Total** | Capacidad total del iPhone | número en GB | ej: 128.0 GB |
| **Brillo de Pantalla** | Nivel actual de brillo | 0-100 (%) | UIScreen.main.brightness |
| **¿Modo Oscuro?** | Si Dark Mode está activo | true/false | Depende de la hora/configuración |
| **¿Notch o Isla Dinámica?** | Si el dispositivo tiene una | true/false | Detecta safeAreaInsets > 20 |

---

## 🚀 Cómo Usarlas en Atajos (Shortcuts)

### Ejemplo 1: Enviar correo solo si hay batería

```
1. Abre la app "Atajos"
2. Crea un nuevo atajo
3. Añade una acción: "Nivel de Batería" (de GmailShortcuts)
4. Pregunta: "¿Es menor a 20%?"
   - SÍ → Mostrar alerta "Batería muy baja para enviar"
   - NO → Continuar a "Enviar correo con Gmail"
5. Guarda
```

### Ejemplo 2: Notificación si descargar archivo solo con WiFi

```
1. Crea un atajo
2. Obtén "Tipo de Conexión"
3. Si es "wifi" → Descargar archivo
4. Si es "cellular" → Mostrar "Usa WiFi para descargar"
5. Si es "unavailable" → Mostrar "Sin internet"
```

### Ejemplo 3: Verificación del dispositivo

```
1. Añade "Modelo de Dispositivo"
2. Añade "Versión de iOS"
3. Mostrar: "Tienes un {modelo} con iOS {versión}"
   Ejemplo output: "Tienes un iPhone 15 Pro con iOS 17.2"
```

### Ejemplo 4: Automación de bajo consumo

```
Cada hora:
1. Si "¿Modo Bajo Consumo?" = true
   - NO resincronizar correos (ahorrar batería)
2. Si = false
   - Sincronizar correos nomalmente
```

---

## 🔧 Implementación Técnica

### Estructura de Servicios

```
GoogleShortcuts/
├── Core/
│   ├── Device/                          ← NUEVO
│   │   ├── DeviceCapabilities.swift     ← Facade principal
│   │   ├── BatteryService.swift         ← Battery info
│   │   ├── ConnectivityService.swift    ← Bluetooth, WiFi, VPN
│   │   ├── DeviceInfoService.swift      ← Model, OS, Storage
│   │   ├── MotionService.swift          ← Orientation, Motion
│   │   ├── AudioMediaService.swift      ← Audio, Silent mode
│   │   ├── NetworkService.swift         ← Connectivity checks
│   │   └── DeviceStateService.swift     ← Lock state, Screen
│   ├── Auth/                            ← Existente (Gmail)
│   ├── API/                             ← Existente (Gmail)
│   ├── Models/                          ← Existente (Gmail)
│   └── Services/                        ← Existente (Gmail)
└── Intents/
    ├── DeviceActionsIntents.swift       ← NUEVO (20+ intents)
    ├── SendEmailIntent.swift            ← Existente (Gmail)
    ├── CheckEmailIntent.swift           ← Existente (Gmail)
    └── ...
```

### Design Patterns Utilizados

1. **Facade Pattern**: `DeviceCapabilities` centraliza acceso a todos los servicios
2. **Actor-based Concurrency**: Todos los servicios son `actor` para thread safety
3. **Separation of Concerns**: Cada servicio responsable de una capacidad
4. **AppIntent Protocol**: Cada acción es una estructura que conforma `AppIntent`

---

## ⚠️ Limitaciones & Permisos

### Qué SÍ funciona en iOS sin entitlements pagos:

- ✅ Battery info (nivel, estado, Low Power Mode)
- ✅ WiFi/Cellular connectivity status (usando NWPathMonitor)
- ✅ VPN status (NEVPNManager)
- ✅ Device info (modelo, nombre, iOS version)
- ✅ Storage info (total, disponible)
- ✅ Screen state (brightness, Dark Mode)
- ✅ Device features (notch, Safe Area)

### Qué NO está disponible (limitaciones de iOS):

- ❌ Bluetooth: Requiere `CBCentralManager` + permisos + Privacy Descriptors
- ❌ Compass heading: Requiere permisos de ubicación + `CLLocationManager`
- ❌ Motion data: Requiere `CMMotionActivityManager` + permisos
- ❌ Audio playback destination: Parcialmente soportado
- ❌ Flashlight, Flight Mode, Hotspot, Orientation Lock (Apple lo bloquea)

### Info.plist Permisos Necesarios (opcionales para máxima funcionalidad):

```xml
<!-- Para Bluetooth -->
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Queremos saber si Bluetooth está activo para sugerencias de atajos</string>

<!-- Para Ubicación (Compass, Elevation) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Acceso a ubicación para brújula y altitud</string>

<!-- Para Motion -->
<key>NSMotionUsageDescription</key>
<string>Acceso a sensores de movimiento para detectar actividad</string>
```

---

## 📊 Casos de Uso Práctica

### 1. **Atajo Inteligente: "Enviar si tiene batería y WiFi"**

```
SI Nivel de Batería > 20% Y Tipo de Conexión = "wifi"
  → Enviar correo
SINO
  → Guardar borrador y esperar conditions mejores
```

### 2. **Automatización Diaria: "Resumen de dispositivo por la mañana"**

```
Cada mañana a las 8:00:
  Mostrar notificación con:
  - Batería: [Nivel]%
  - Espacio: [Disponible] GB
  - Conexión: [Tipo]
  - iOS: [Versión]
```

### 3. **Automatización Smart: "Optimizar según estado"**

```
SI Modo Bajo Consumo = true
  → Reducir frecuencia de sincronización
  → Desactivar animaciones en app
  → Notificación cada 30 min en lugar de cada 5

SI Batería < 10%
  → Enviar alerta inmediata
  → Pausar cualquier descarga
```

### 4. **Condicional de Conectividad**

```
SI ¿Online? = true
  SI Tipo = "wifi"
    → Descargar archivos adjuntos
  SI Tipo = "cellular"
    → Previsualizar textos solamente (datos limitados)
SINO
  → Modo offline, trabajo con caché
```

---

## 🔄 Próximas Extensiones Planeadas

Acciones adicionales que se pueden agregar fácilmente:

- 🎵 **Audio/Media**: Get/Set volumen, Detectar app de música activa
- 📍 **Location**: Obtener coordenadas, Zona horaria (ya implementada)
- 🎥 **Camera**: Detectar si hay cámara disponible
- 👁️ **Privacy**: Estado de los permisos por app
- 🎚️ **System**: Volume buttons, Haptics control
- 📲 **Phone**: Si hay llamada activa, SIM info

---

## 💡 Tips & Tricks

### Tip 1: Usar Device Actions para debugging

```
Al inicio de cada atajo importante:
  → "Nivel de Batería" → Loguear
  → "¿Online?" → Loguear
  → "Versión de iOS" → Loguear
Esto ayuda a saber por qué falló un atajo
```

### Tip 2: Crear atajos "system monitor"

```
Crea un atajo que cada hora te diga:
  "Batería: 45% | WiFi: Act | Almacén libre: 32GB"
Úsalo como widget en home screen
```

### Tip 3: Chains condicionales con Device Actions

```
Si [DeviceAction1] Y [DeviceAction2] Y [DeviceAction3]
  → Hacer acción compleja

Esto permite crear atajos muy sofisticados
```

---

## 🐛 Troubleshooting

### "Las acciones no aparecen en Atajos"

1. Asegúrate que la app está **instalada en el iPhone**
2. **Fuerza el cierre** de la app "Atajos"
3. Abre "Atajos" de nuevo → debería descubrirlas automáticamente
4. Si no: **reinicia el iPhone**

### "Una acción devuelve valor incorrecto"

1. Verifica que tienes iOS 16.0 o superior
2. Prueba en diferente contexto (WiFi vs Cellular)
3. Reporta en GitHub si es bug

### "Necesito más acciones"

1. Crea un issue en GitHub con la solicitud
2. Puedo agregar nuevas acciones rápidamente
3. El framework está diseñado para expandirse fácilmente

