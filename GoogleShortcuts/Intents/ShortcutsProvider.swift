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
/// - "Enviar correo con Gmail" → SendEmailIntent
/// - "Consultar últimos correos" → CheckRecentEmailsIntent
/// - "Buscar correos por asunto" → SearchEmailsIntent
/// - "Verificar correos nuevos" → CheckNewEmailsIntent
/// - "Contar correos no leídos" → UnreadCountIntent
struct GoogleShortcutsShortcutsProvider: AppShortcutsProvider {
    
    /// Shortcuts predefinidos que aparecen en la app Shortcuts.
    static var appShortcuts: [AppShortcut] {
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
    }
}
