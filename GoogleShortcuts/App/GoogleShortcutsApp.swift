import SwiftUI
import BackgroundTasks

/// Entry point de la aplicación.
/// Configurado para iOS 16+ con App Intents (no requiere cuenta paga).
@main
struct GoogleShortcutsApp: App {
    
    @StateObject private var authManager = OAuthManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
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
        print("[OAuth] URL recibida: \(url)")
        print("[OAuth] Scheme: \(url.scheme ?? "nil")")
        print("[OAuth] Host: \(url.host ?? "nil")")
        print("[OAuth] Path: \(url.path)")
        
        // OAuth2 callback de Google
        if url.scheme?.starts(with: "com.googleusercontent.apps") == true {
            print("[OAuth] ✅ Reconocida como callback de Google")
            Task {
                await authManager.handleOAuthCallback(url: url)
            }
            return
        }
        
        // Deep links propios (googleshortcuts://)
        if url.scheme == "googleshortcuts" {
            print("[OAuth] ✅ Reconocida como deep link propio")
            handleDeepLink(url)
            return
        }
        
        print("[OAuth] ❌ URL no reconocida")
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

// MARK: - App Delegate con Background App Refresh

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let clipboardRefreshTaskID = "com.abel.shortcuts.clipboard-refresh"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerBackgroundAppRefresh()
        scheduleClipboardRefresh()
        return true
    }
    
    // MARK: - Background App Refresh
    
    private func registerBackgroundAppRefresh() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: Self.clipboardRefreshTaskID,
                using: nil
            ) { [weak self] task in
                self?.handleClipboardRefreshTask(task: task as! BGProcessingTask)
            }
            
            // Escuchar cuando se vuelve a foreground para reprogramar
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleClipboardRefresh()
            }
        }
    }
    
    private func handleClipboardRefreshTask(task: BGProcessingTask) {
        // Agendar la siguiente tarea inmediatamente
        scheduleNextClipboardRefresh()
        
        // Ejecutar chequeo en main thread
        Task { @MainActor in
            ClipboardService.shared.checkClipboard()
            task.setTaskCompleted(success: true)
        }
        
        // Timeout: marcar como completada después de 30s
        let deadline = DispatchTime.now() + .seconds(30)
        DispatchQueue.global().asyncAfter(deadline: deadline) {
            if !Task.isCancelled {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    /// Programa la siguiente ejecución de Background Refresh
    /// iOS ejecuta más frecuentemente si detecta uso frecuente de la app
    func scheduleClipboardRefresh() {
        if #available(iOS 13.0, *) {
            // Cancelar tareas previas para evitar duplicados
            BGTaskScheduler.shared.cancelAllTaskRequests()
            
            let request = BGProcessingTaskRequest(identifier: Self.clipboardRefreshTaskID)
            
            // Configurar requisitos mínimos
            request.requiresNetworkConnectivity = false
            request.requiresExternalPower = false
            
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                // Error silencioso para production
            }
        }
    }
    
    private func scheduleNextClipboardRefresh() {
        scheduleClipboardRefresh()
    }
}

