import SwiftUI

/// Entry point de la aplicación.
/// Configurado para iOS 16+ con App Intents (no requiere cuenta paga).
@main
struct GoogleShortcutsApp: App {
    
    @StateObject private var authManager = OAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // Maneja el callback de OAuth2 desde el navegador
                    handleIncomingURL(url)
                }
        }
    }
    
    /// Procesa URLs entrantes (OAuth callback y deep links de Shortcuts).
    ///
    /// Esquemas soportados:
    /// - `com.googleusercontent.apps.CLIENT_ID://` → OAuth callback
    /// - `googleshortcuts://` → Deep links desde Shortcuts
    private func handleIncomingURL(_ url: URL) {
        // OAuth2 callback de Google
        if url.scheme?.starts(with: "com.googleusercontent.apps") == true {
            Task {
                await authManager.handleOAuthCallback(url: url)
            }
            return
        }
        
        // Deep links propios (googleshortcuts://)
        if url.scheme == "googleshortcuts" {
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        
        switch host {
        case "send":
            // googleshortcuts://send?to=...&subject=...&body=...
            // Se maneja via App Intents, este es un fallback
            break
        case "check":
            // googleshortcuts://check
            break
        default:
            break
        }
    }
}
