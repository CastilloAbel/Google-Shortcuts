# GoogleShortcuts - Gmail + Device Actions for iOS Shortcuts

App iOS que integra **Gmail** y **Device Actions** con Apple Shortcuts mediante App Intents.

## ✨ Características Principales

### Gmail Integration
- ✉️ Enviar correos via Gmail API desde Shortcuts
- 📥 Consultar últimos correos recibidos
- 🔍 Buscar correos por asunto/remitente
- 🔄 Polling de nuevos correos (sin push notifications)
- 🔐 Autenticación OAuth2 con Google (PKCE)

### Device Actions (NUEVO v2.0)
- 🔋 Información de batería (nivel, estado, bajo consumo)
- 📡 Conectividad (Bluetooth, WiFi, VPN, datos móviles)
- 📱 Información del dispositivo (modelo, nombre, iOS version)
- 💾 Almacenamiento y pantalla (espacio, brillo, Dark Mode)
- 🌐 Estado de red (conectado, tipo de conexión)
- **20+ acciones en total**

## Ventajas

- 📱 Compatible con cuenta Apple **gratuita** (sin Developer Program)
- ⚙️ Device Actions funcionan **sin autenticación** y **offline**
- 🎯 Ideal para automatizar Atajos complejos
- 📦 Instalable via SideStore / LiveContainer

## Arquitectura v2.0

```
GoogleShortcuts/
├── App/                         → Entry point SwiftUI
├── Core/
│   ├── Auth/                   → OAuth2 + PKCE, token storage
│   ├── API/                    → Gmail API client, HTTP layer
│   ├── Models/                 → Email, GmailResponse DTOs
│   ├── Services/               → Email + Polling services
│   └── Device/ (NUEVO v2.0)    → Battery, Connectivity, DeviceInfo
│                                 Motion, Audio, Network, DeviceState
├── Intents/
│   ├── ShortcutsProvider.swift → Registro de todos los intents (25+)
│   ├── SendEmailIntent.swift   → Enviar correos
│   ├── CheckEmailIntent.swift  → Consultar correos
│   ├── SearchEmailIntent.swift → Buscar correos
│   └── DeviceActionsIntents.swift (NUEVO v2.0) → 20+ device actions
├── UI/                         → Vistas SwiftUI
└── Resources/                  → Assets, Info.plist
```

## Requisitos

- iOS 16.0+
- Apple ID gratuito
- Google Cloud Console (proyecto con Gmail API habilitada)
- SideStore o LiveContainer para instalar

## Documentación

- **[🚨 CRÍTICO: OAuth2 Fix + Setup](docs/OAUTH_FIX_AND_SETUP.md)** ← EMPIEZA AQUÍ si OAuth no funciona
- [📖 Device Actions - Guía Completa](docs/DEVICE_ACTIONS.md)
- [🏗️ Arquitectura v2.0](docs/ARCHITECTURE_V2.md)
- [🔨 Guía de Compilación v2.0](docs/COMPILATION_GUIDE_V2.md)
- [📋 Configuración OAuth Google](docs/OAUTH_SETUP.md) (original)
- [📦 Guía de Build](docs/BUILD_GUIDE.md) (original)
- [📱 Guía de Sideloading](docs/SIDELOAD_GUIDE.md) (original)

## Limitaciones (cuenta Apple gratuita)

- App expira cada 7 días (re-firmar con SideStore)
- Sin push notifications (se usa polling)
- Sin Associated Domains (se usa URL Scheme en su lugar)
- Sin background modes avanzados
- Máximo 3 apps sideloaded simultáneamente
