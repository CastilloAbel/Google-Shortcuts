# 📊 Diagramas de Arquitectura v2.0

## Estructura General de Módulos

```
┌─────────────────────────────────────────────────────────────┐
│                    App Entry Point                          │
│            (GoogleShortcutsApp.swift)                      │
└────────────────┬────────────────────────────────────────────┘
                 │
     ┌───────────┴──────────────┐
     │                          │
┌────▼──────────────┐   ┌──────▼──────┐
│   Auth Layer      │   │   Intent    │
│   (OAuth2+PKCE)   │   │   Registry  │
└────┬──────────────┘   └─────────────┘
     │
     ├─► Core Authentication
     │   ├─► OAuthConfig (Google endpoints, scopes)
     │   ├─► OAuthManager (login flow)
     │   └─► TokenStorage (Keychain persistence)
     │
     └─► HTTP + API Layer
         ├─► HTTPClient (generic async HTTP)
         │   └─► GmailAPIClient (Gmail API v1)
         │
         ├─► Models
         │   └─► Email + Email-related structures
         │
         ├─► Services (Gmail-specific)
         │   ├─► EmailService (high-level)
         │   └─► MailPollingService (background)
         │
         └─► Device Services (NUEVO v2.0)
             ├─► BatteryService
             ├─► ConnectivityService
             ├─► DeviceInfoService
             ├─► MotionService
             ├─► AudioMediaService
             ├─► NetworkService
             └─► DeviceStateService
                 (Centralizados en DeviceCapabilities)

         ├─► Intents (App Intents para Shortcuts)
         │   ├─► Gmail Intents (5)
         │   └─► Device Actions Intents (20+)
         │       └─► Registrados en ShortcutsProvider
         │
         └─► UI (SwiftUI)
             ├─► AuthView
             ├─► ContentView
             ├─► EmailListView
             └─► SettingsView
```

## Device Actions Services Diagram

```
                    ┌──────────────────┐
                    │ DeviceCapabilities│
                    │   (Facade)       │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐           ┌──▼──┐            ┌───▼──┐
   │ Battery │           │ Conn│            │Device│
   │Service  │           │ectiv│            │Info  │
   │         │           │ityS │            │Svc   │
   └────────┘           └─────┘            └──────┘
        │                    │                    │
   • Level              • BT Status           • Model
   • State              • WiFi Status         • Name
   • Low Power          • VPN Status          • OS Ver
   • Est. Time          • Cellular            • Storage
                        • 5G Tech             • Brightness
                                              • Dark Mode
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Motion Service  │
                    │ Audio Service   │
                    │ Network Service │
                    │ Device State Sv │
                    └─────────────────┘
                             │
             ┌───────────────┼───────────────┐
             │               │               │
         • Orientation   • Audio Status  • Online
         • Motion        • Playback      • Connection
         • Compass       • Silent Mode   • Type
         • Elevation     • Volume        • Device Lock
                                         • Screen
```

## Intent Registration Flow

```
                    ┌──────────────────┐
                    │ ShortcutsProvider│
                    │ (AppShortcuts)   │
                    └────────┬─────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
    ┌───▼──────┐                          ┌──────▼──┐
    │ Gmail    │                          │ Device  │
    │Intents  │                          │Intents  │
    │ (5)     │                          │ (20+)   │
    └────┬────┘                          └────┬────┘
         │                                    │
    • Send Email                          • Batería (4)
    • Check Recent                        • Conectividad (4)
    • Search                              • Dispositivo (3)
    • Check New                           • Red & Storage (5+)
    • Unread Count                        • Estado (3+)
         │                                    │
         └────────────┬──────────────────────┘
                      │
            ┌─────────▼──────────┐
            │  App Intents       │
            │  (iOS 16+)         │
            │                    │
            │  Descubrimiento    │
            │  automático en     │
            │  app Atajos(Scut)  │
            └────────────────────┘
                      │
         Disponibles en: Atajos → Buscar "GmailShortcuts"
```

## Data Flow: OAuth2 → Gmail → Device Actions

```
Usuario abre app
        │
   ┌────▼────────────┐
   │ ¿Autenticado?   │
   └────┬─────┬──────┘
        │YES  │NO
        │     └──► AuthView
        │         │
        │     ┌───▼─────────┐
        │     │ Toca Login  │
        │     └───┬─────────┘
        │         │
        │     ┌───▼──────────────────┐
        │     │Safari: Google OAuth  │
        │     │code_verifier + PKCE  │
        │     └───┬──────────────────┘
        │         │
        │     ┌───▼──────────────┐
        │     │ User autoriza    │
        │     │ (Email + scopes) │
        │     └───┬──────────────┘
        │         │
        │     ┌───▼──────────────────────┐
        │     │ Redirect → handleCallback│
        │     │ intercept code + exchange│
        │     └───┬──────────────────────┘
        │         │
        │     ┌───▼─────────────┐
        │     │ Token Exchange  │
        │     │ Google → Token  │
        │     └───┬─────────────┘
        │         │
        │     ┌───▼────────────────┐
        │     │ Save (Keychain)    │
        │     │ + User Email       │
        │     └───┬────────────────┘
        │         │
        └────┬────┘
             │
        ┌────▼──────────┐
        │  Autenticado  │
        │  ContentView  │
        └────┬──────────┘
             │
    ┌────────┴─┬──────────────┐
    │           │              │
┌───▼───┐  ┌───▼────┐  ┌──────▼────┐
│Inbox  │  │Settings│  │ Atajos... │
├───┬───┤  └────────┘  └───┬───────┘
│   │                      │
│ Require Gmail Token      │ NO require token
│ Call GmailAPIClient      │ (offline)
│ with Access Token        │
│ → HTTPClient with auth   │ Device Actions
│ → Gmail API endpoints    │ • Battery
│ → Email models           │ • Connectivity
└───┘                      │ • Device Info
                           │ etc.
                           └────────────┘
```

## Service Actor Concurrency

```
              ┌──────────────────────┐
              │ Main Thread (UI)     │
              │ @MainActor           │
              └──────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    ┌───▼──┐    ┌──────▼───┐  ┌──────▼──┐
    │ OAuth│    │ EmailSvc │  │ Device  │
    │Mgr   │    │ (Actor)  │  │Services │
    │      │    │          │  │(Actors) │
    └──────┘    └──────────┘  └─────────┘
      @Main        Concurrent      Concurrent
      Actor         Execution      Execution
        │              │               │
        ├─ TokenStore  │ HTTPClient   │ BatteryService
        │ (Keychain)   │ (Generic)    │ (Non-isolated)
        │              │              │
        │              │ GmailAPI     │ ConnectivitySvc
        │              │ Client       │ (Non-isolated)
        │              │              │
        │              │              │ DeviceInfoSvc
        │              │              │ (Non-isolated)
        │              │              │
        │              │              │ MotionService
        │              │              │ AudioMediaSvc
        │              │              │ NetworkService
        │              │              │ DeviceStateSvc
        │              │              │
        └──────────────┴──────────────┘
              Thread-Safe Boundary
```

## Integration: Atajos App Example

```
┌──────────────────────────────────────┐
│   Apple Atajos (Shortcuts) App      │
└─────────────────┬────────────────────┘
                  │
        ┌─────────┴────────┐
        │                  │
    ┌───▼─────┐        ┌───▼──────┐
    │ Buscar  │        │ Importar │
    │"Gmail"  │        │ Atajo    │
    └───┬─────┘        └──────────┘
        │
    Descubre:
    ├─ "Enviar correo c/ Gmail"
    ├─ "Ver últimos correos"
    ├─ "Buscar correos"
    ├─ "Verificar nuevos"
    ├─ "Contar no leídos"
    │
    └─ "Nivel de batería"
    ├─ "¿Batería baja?"
    ├─ "¿Bluetooth?"
    ├─ "¿WiFi?"
    ├─ "Modelo dispositivo"
    ├─ "Versión iOS"
    ├─ "¿Online?"
    ├─ "Espacio disponible"
    ├─ "¿Modo oscuro?"
    └─ ...19+ más
        │
    ┌───▼─────────────────────┐
    │ Crea Atajo:             │
    │"Enviar si WiFi y Batería│
    │                         │
    │ 1. ¿WiFi? = true       │
    │ 2. Nivel > 20%         │
    │ 3. YES → Enviar email   │
    │ 4. NO → Mostrar alerta  │
    └─────────────────────────┘
```

---

**Generado**: 7 de abril de 2026
**Versión**: v2.0 Architecture

