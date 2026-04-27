import Foundation
import UIKit
import UserNotifications
import BackgroundTasks

/// Servicio para monitorear cambios en el portapapeles en foreground y background
/// - En **foreground**: Monitorea en tiempo real (cada 0.5 segundos)
/// - En **background**: Chequea cada 15 minutos (vía Background Tasks)
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
    
    /// Inicia el monitoreo del portapapeles
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("🎯 Clipboard monitoring iniciado")
        
        // Registrar background task
        registerBackgroundTask()
        
        // Inicializar estado actual
        updateClipboardState()
        
        // Monitoreo en foreground
        DispatchQueue.global().async { [weak self] in
            while true {
                DispatchQueue.main.async {
                    self?._checkClipboardForChanges()
                }
                Thread.sleep(forTimeInterval: 0.5) // Chequeo cada 500ms
            }
        }
    }
    
    // MARK: - Detección de Cambios
    
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
        Task {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = "Portapapeles Actualizado"
            notificationContent.body = String(content.prefix(100))
            notificationContent.sound = .default
            
            // Obtener badge count de forma segura
            let badgeNumber = await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber
            }
            notificationContent.badge = NSNumber(value: badgeNumber + 1)
            
            // Pequeño delay para que se vea como notificación de background
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
            
            do {
                try await notificationCenter.add(request)
                print("✅ Notificación enviada")
            } catch {
                print("❌ Error enviando notificación: \(error)")
            }
        }
    }
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTask() {
        // Registrar task que se ejecuta cada 15 minutos
        let request = BGProcessingTaskRequest(identifier: backgroundTaskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background task registrado: cada ~15 minutos")
        } catch {
            print("❌ Error registrando background task: \(error)")
        }
    }
    
    /// Debe llamarse desde AppDelegate cuando el background task se ejecuta
    static func handleBackgroundClipboardTask(task: BGProcessingTask) {
        ClipboardMonitoringService.shared._checkClipboardForChanges()
        
        // Re-schedule para la próxima ejecución
        ClipboardMonitoringService.shared.registerBackgroundTask()
        
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - Obtener Contenido Actual
    
    /// Obtiene el contenido actual del portapapeles formateado
    func getCurrentClipboardContent() -> String? {
        return getClipboardContent()
    }
}
