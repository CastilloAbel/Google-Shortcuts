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
    
    /// Inicia el monitoreo del portapapeles (una sola vez, seguro)
    func startMonitoring() {
        guard !isMonitoring else {
            print("⚠️ El monitoreo ya estaba activo")
            return
        }
        
        isMonitoring = true
        print("🎯 Clipboard monitoring iniciado")
        
        do {
            // Inicializar estado actual (protegido)
            try updateClipboardState()
            
            // Registrar observer para cambios de portapapeles (protegido)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clipboardDidChange),
                name: UIPasteboard.changedNotification,
                object: nil
            )
            
            print("✅ Observer registrado")
            
            // Registrar background task (protegido)
            registerBackgroundTask()
        } catch {
            print("❌ Error iniciando monitoreo: \(error.localizedDescription)")
            isMonitoring = false
        }
    }
    
    // MARK: - Detección de Cambios
    
    @objc private func clipboardDidChange() {
        do {
            try _checkClipboardForChanges()
        } catch {
            print("❌ Error al revisar portapapeles: \(error.localizedDescription)")
        }
    }
    
    private func _checkClipboardForChanges() throws {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        // Si el count cambió, hay algo nuevo
        guard currentChangeCount != lastChangeCount else {
            return
        }
        
        lastChangeCount = currentChangeCount
        
        if let content = try getClipboardContent() {
            // Verificar que sea diferente del último conocido
            if content != lastPasteboardContent {
                lastPasteboardContent = content
                
                // Notificar al usuario (non-throwing)
                notifyClipboardChange(content: content)
                
                print("📋 Portapapeles actualizado: \(content.prefix(50))...")
            }
        }
    }
    
    private func updateClipboardState() throws {
        lastChangeCount = UIPasteboard.general.changeCount
        lastPasteboardContent = try getClipboardContent()
    }
    
    // MARK: - Obtención de Contenido
    
    private func getClipboardContent() throws -> String? {
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
        // Crear notificación de forma segura
        Task {
            do {
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = "📋 Portapapeles"
                notificationContent.body = String(content.prefix(100))
                notificationContent.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: notificationContent,
                    trigger: trigger
                )
                
                try await notificationCenter.add(request)
                print("✅ Notificación enviada")
            } catch {
                print("⚠️ No se pudo enviar notificación: \(error.localizedDescription)")
                // No crashear si falla la notificación
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
            print("⚠️ No se pudo registrar background task: \(error.localizedDescription)")
            // No es crítico si falla
        }
    }
    
    /// Llamado desde AppDelegate cuando se ejecuta el background task
    static func handleBackgroundClipboardTask(task: BGProcessingTask) {
        do {
            try ClipboardMonitoringService.shared._checkClipboardForChanges()
            ClipboardMonitoringService.shared.registerBackgroundTask()
            task.setTaskCompleted(success: true)
        } catch {
            print("❌ Error en background task: \(error.localizedDescription)")
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Obtener Contenido Actual
    
    func getCurrentClipboardContent() -> String? {
        do {
            return try getClipboardContent()
        } catch {
            print("⚠️ Error obteniendo portapapeles: \(error.localizedDescription)")
            return nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
