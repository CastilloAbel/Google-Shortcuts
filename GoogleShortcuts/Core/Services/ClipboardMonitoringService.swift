import Foundation
import UIKit
import UserNotifications
import BackgroundTasks

/// Servicio para monitorear cambios en el portapapeles
/// Usa NotificationCenter para observar cambios (sin polling)
final class ClipboardMonitoringService: NSObject, ObservableObject {
    static let shared = ClipboardMonitoringService()
    
    private var lastPasteboardContent: String?
    private var lastChangeCount: Int = 0
    private var isMonitoring = false
    private let notificationCenter = UNUserNotificationCenter.current()
    private let backgroundTaskID = "com.abel.googleshortcuts.clipboard.monitoring"
    
    override private init() {
        super.init()
    }
    
    // MARK: - Iniciación del Monitoreo
    
    /// Inicia el monitoreo del portapapeles (una sola vez)
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🎯 Clipboard monitoring iniciado")
        
        // Inicializar estado actual
        updateClipboardState()
        
        // Registrar observer para cambios de portapapeles
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipboardDidChange),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        
        // Registrar background task
        registerBackgroundTask()
    }
    
    // MARK: - Detección de Cambios
    
    @objc private func clipboardDidChange() {
        _checkClipboardForChanges()
    }
    
    private func _checkClipboardForChanges() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        // Si el count cambió, hay algo nuevo
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let content = getClipboardContent() {
                // Verificar que sea diferente del último conocido
                if content != lastPasteboardContent {
                    lastPasteboardContent = content
                    
                    // Notificar al usuario
                    notifyClipboardChange(content: content)
                    
                    print("📋 Portapapeles actualizado: \(content.prefix(50))...")
                }
            }
        }
    }
    
    private func updateClipboardState() {
        lastChangeCount = UIPasteboard.general.changeCount
        lastPasteboardContent = getClipboardContent()
    }
    
    // MARK: - Obtención de Contenido
    
    private func getClipboardContent() -> String? {
        let pasteboard = UIPasteboard.general
        
        // Intentar obtener texto
        if let text = pasteboard.string, !text.isEmpty {
            return "📝 Texto: \(text)"
        }
        
        // Intentar obtener URL
        if let url = pasteboard.url {
            return "🔗 URL: \(url.absoluteString)"
        }
        
        // Intentar obtener imagen
        if pasteboard.image != nil {
            return "🖼️ Imagen copiada"
        }
        
        // Intentar obtener color
        if pasteboard.color != nil {
            return "🎨 Color copiado"
        }
        
        return nil
    }
    
    // MARK: - Notificaciones
    
    private func notifyClipboardChange(content: String) {
        // Notificación local (no remota)
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "📋 Portapapeles"
        notificationContent.body = String(content.prefix(100))
        notificationContent.sound = .default
        
        // Pequeño delay para que se vea como notificación de background
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        
        Task {
            do {
                try await notificationCenter.add(request)
                print("✅ Notificación enviada")
            } catch {
                print("❌ Error enviando notificación: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background task registrado")
        } catch {
            print("❌ Error registrando background task: \(error.localizedDescription)")
        }
    }
    
    /// Llamado desde AppDelegate cuando se ejecuta el background task
    static func handleBackgroundClipboardTask(task: BGProcessingTask) {
        ClipboardMonitoringService.shared._checkClipboardForChanges()
        ClipboardMonitoringService.shared.registerBackgroundTask()
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - Obtener Contenido Actual
    
    func getCurrentClipboardContent() -> String? {
        return getClipboardContent()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
