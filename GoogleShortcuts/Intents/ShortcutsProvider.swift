import AppIntents

/// Proveedor de Shortcuts para la app.
///
/// Registra todos los App Intents disponibles en la app de Shortcuts.
/// iOS 16+ descubre automáticamente los intents que conforman AppIntent.
///
/// ## ¿Funciona con cuenta Apple gratuita?
/// ✅ SÍ. App Intents NO requiere entitlements pagos.
/// Los intents se registran automáticamente al instalar la app.
/// Funcionan correctamente con apps sideloaded via SideStore.
///
/// ## Acciones disponibles en Shortcuts:
/// ### Gmail (Autenticación requerida)
/// - "Enviar correo con Gmail" → SendEmailIntent
/// - "Consultar últimos correos" → CheckRecentEmailsIntent
/// - "Buscar correos" → SearchEmailsIntent
/// - "Verificar correos nuevos" → CheckNewEmailsIntent
/// - "Contar correos no leídos" → UnreadCountIntent
///
/// ### Device Actions (Sin autenticación)
/// #### Batería
/// - "Obtener nivel de batería" → GetBatteryLevelIntent
/// - "¿Batería baja?" → IsBatteryLowIntent
/// - "Estado de batería" → GetBatteryStateIntent
/// - "¿Modo bajo consumo?" → IsLowPowerModeOnIntent
///
/// #### Conectividad
/// - "¿Bluetooth encendido?" → IsBluetoothOnIntent
/// - "¿WiFi encendido?" → IsWiFiOnIntent
/// - "¿VPN conectado?" → IsVPNConnectedIntent
/// - "¿Datos móviles?" → IsCellularDataOnIntent
///
/// #### Dispositivo & Red
/// - "Modelo de dispositivo" → GetDeviceModelIntent
/// - "Nombre del dispositivo" → GetDeviceNameIntent
/// - "Versión de iOS" → GetiOSVersionIntent
/// - "¿Conectado a internet?" → IsOnlineIntent
/// - "Tipo de conexión" → GetConnectionTypeIntent
///
/// #### Almacenamiento & Pantalla
/// - "Espacio disponible" → GetAvailableStorageIntent
/// - "Almacenamiento total" → GetTotalStorageIntent
/// - "Brillo de pantalla" → GetScreenBrightnessIntent
/// - "¿Modo oscuro?" → IsDarkModeOnIntent
/// - "¿Tiene notch o isla dinámica?" → HasNotchOrIslandIntent
struct GoogleShortcutsShortcutsProvider: AppShortcutsProvider {
    
    /// Shortcuts predefinidos que aparecen en la app Shortcuts.
    static var appShortcuts: [AppShortcut] {
        // MARK: - Gmail Actions
        
        AppShortcut(
            intent: SendEmailIntent(),
            phrases: [
                "Enviar correo con \(.applicationName)",
                "Enviar email con \(.applicationName)",
                "Mandar correo con \(.applicationName)"
            ],
            shortTitle: "Enviar Correo",
            systemImageName: "paperplane.fill"
        )
        
        AppShortcut(
            intent: CheckRecentEmailsIntent(),
            phrases: [
                "Ver últimos correos en \(.applicationName)",
                "Consultar correos en \(.applicationName)",
                "Revisar inbox con \(.applicationName)"
            ],
            shortTitle: "Últimos Correos",
            systemImageName: "envelope.fill"
        )
        
        AppShortcut(
            intent: SearchEmailsIntent(),
            phrases: [
                "Buscar correo en \(.applicationName)",
                "Buscar email en \(.applicationName)"
            ],
            shortTitle: "Buscar Correos",
            systemImageName: "magnifyingglass"
        )
        
        AppShortcut(
            intent: CheckNewEmailsIntent(),
            phrases: [
                "Verificar correos nuevos en \(.applicationName)",
                "Hay correos nuevos en \(.applicationName)"
            ],
            shortTitle: "Correos Nuevos",
            systemImageName: "bell.fill"
        )
        
        AppShortcut(
            intent: UnreadCountIntent(),
            phrases: [
                "Cuántos correos sin leer en \(.applicationName)",
                "Correos no leídos en \(.applicationName)"
            ],
            shortTitle: "No Leídos",
            systemImageName: "envelope.badge"
        )
        
        // MARK: - Device Actions: Battery
        
        AppShortcut(
            intent: GetBatteryLevelIntent(),
            phrases: [
                "Nivel de batería",
                "Porcentaje de batería",
                "¿Cuánta batería queda?"
            ],
            shortTitle: "Nivel de Batería",
            systemImageName: "battery.50"
        )
        
        AppShortcut(
            intent: IsBatteryLowIntent(),
            phrases: [
                "¿Batería baja?",
                "Verificar si batería baja"
            ],
            shortTitle: "¿Batería Baja?",
            systemImageName: "battery.25"
        )
        
        AppShortcut(
            intent: IsLowPowerModeOnIntent(),
            phrases: [
                "¿Modo bajo consumo?",
                "¿Ahorro de energía?"
            ],
            shortTitle: "Modo Bajo Consumo",
            systemImageName: "bolt.badge"
        )
        
        // MARK: - Device Actions: Connectivity
        
        AppShortcut(
            intent: IsBluetoothOnIntent(),
            phrases: [
                "¿Bluetooth?",
                "¿Bluetooth activo?",
                "Bluetooth encendido"
            ],
            shortTitle: "Bluetooth",
            systemImageName: "bluetooth"
        )
        
        // TEMPORARILY DISABLED: Testing remaining Connectivity Device Actions
        /*
        AppShortcut(
            intent: IsWiFiOnIntent(),
            phrases: [
                "¿WiFi?",
                "¿WiFi conexión?",
                "¿Conectado a WiFi?"
            ],
            shortTitle: "WiFi",
            systemImageName: "wifi"
        )
        
        AppShortcut(
            intent: IsVPNConnectedIntent(),
            phrases: [
                "¿VPN?",
                "¿VPN activo?"
            ],
            shortTitle: "VPN",
            systemImageName: "network"
        )
        */
        
        // MARK: - Device Actions: Device Info
        // TEMPORARILY DISABLED: Testing which Device Action causes ExtractAppIntentsMetadata error
        /*
        AppShortcut(
            intent: GetDeviceModelIntent(),
            phrases: [
                "¿Qué iPhone tengo?",
                "Modelo del dispositivo"
            ],
            shortTitle: "Modelo del Dispositivo",
            systemImageName: "iphone"
        )
        
        AppShortcut(
            intent: GetiOSVersionIntent(),
            phrases: [
                "Versión de iOS",
                "¿Qué versión de iOS?"
            ],
            shortTitle: "Versión de iOS",
            systemImageName: "info.circle"
        )
        
        // MARK: - Device Actions: Network & Storage
        
        AppShortcut(
            intent: IsOnlineIntent(),
            phrases: [
                "¿Internet?",
                "¿Online?",
                "¿Conectado?"
            ],
            shortTitle: "¿Online?",
            systemImageName: "globe"
        )
        
        AppShortcut(
            intent: GetAvailableStorageIntent(),
            phrases: [
                "Espacio disponible",
                "¿Cuánto espacio libre?"
            ],
            shortTitle: "Espacio Libre",
            systemImageName: "internaldrive"
        )
        */
    }
}
