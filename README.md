# GoogleShortcuts - Gmail Automation for iOS Shortcuts

App iOS que integra Gmail con Apple Shortcuts mediante App Intents.

## Características

- ✉️ Enviar correos via Gmail API desde Shortcuts
- 📥 Consultar últimos correos recibidos
- 🔍 Buscar correos por asunto/remitente
- 🔄 Polling de nuevos correos (sin push notifications)
- 🔐 Autenticación OAuth2 con Google (PKCE)
- 📱 Compatible con cuenta Apple gratuita
- 📦 Instalable via SideStore / LiveContainer

## Arquitectura

```
GoogleShortcuts/
├── App/                    → Entry point SwiftUI
├── Core/
│   ├── Auth/              → OAuth2 + PKCE, token storage
│   ├── API/               → Gmail API client, HTTP layer
│   ├── Models/            → Email, GmailResponse DTOs
│   └── Services/          → Email service, polling service
├── Intents/               → App Intents para Shortcuts
├── UI/                    → Vistas SwiftUI
└── Resources/             → Assets, Info.plist
```

## Requisitos

- iOS 16.0+
- Apple ID gratuito
- Google Cloud Console (proyecto con Gmail API habilitada)
- SideStore o LiveContainer para instalar

## Documentación

- [Configuración OAuth Google](docs/OAUTH_SETUP.md)
- [Guía de Compilación](docs/BUILD_GUIDE.md)
- [Guía de Sideloading](docs/SIDELOAD_GUIDE.md)
- [Alternativa sin App Nativa](docs/NO_APP_ALTERNATIVE.md)

## Limitaciones (cuenta Apple gratuita)

- App expira cada 7 días (re-firmar con SideStore)
- Sin push notifications (se usa polling)
- Sin Associated Domains (se usa URL Scheme en su lugar)
- Sin background modes avanzados
- Máximo 3 apps sideloaded simultáneamente
