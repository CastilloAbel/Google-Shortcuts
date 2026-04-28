import Foundation
import UIKit
import SwiftUI

/// Modelo para un item del portapapeles
public struct ClipboardItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let type: ContentType
    
    public enum ContentType: String, Codable, Sendable {
        case text
        case url
        case image
        case unknown
    }
    
    public init(content: String, type: ContentType = .text) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
    }
    
    public var displayText: String {
        let maxLength = 100
        return content.count > maxLength
            ? String(content.prefix(maxLength)) + "..."
            : content
    }
    
    public var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Servicio centralizado para gestionar el portapapeles
/// Ejecuta SOLO en MainActor para evitar problemas de concurrencia
@MainActor
final class ClipboardService: NSObject, ObservableObject {
    static let shared = ClipboardService()
    
    @Published var history: [ClipboardItem] = []
    @Published var currentContent: String = ""
    
    private var lastPasteboardChangeCount: Int = 0
    private var monitoringTimer: Timer?
    private let maxHistoryItems = 50
    private let userDefaultsKey = "clipboard_history"
    
    nonisolated private override init() {
        super.init()
    }
    
    // MARK: - Inicialización
    
    /// Inicializa el servicio (debe llamarse en MainActor)
    func initializeService() {
        print("📋 Inicializando ClipboardService...")
        loadHistory()
        startMonitoring()
        registerBackgroundNotifications()
    }
    
    nonisolated private func registerBackgroundNotifications() {
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appDidEnterForeground),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }
    
    @objc private func appDidEnterForeground() {
        print("📱 App en foreground - reanudando monitoreo")
        startMonitoring()
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App en background - pausando monitoreo")
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Inicia el monitoreo del portapapeles
    func startMonitoring() {
        guard monitoringTimer == nil else {
            print("⚠️ Monitoreo ya está activo")
            return
        }
        
        // Inicializar estado
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
        print("📊 ChangeCount inicial: \(lastPasteboardChangeCount)")
        
        // Crear timer que monitorea cada 0.5 segundos
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        
        print("✅ Monitoreo iniciado - Timer activo")
    }
    }
    
    /// Detiene el monitoreo
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("⏸️ Monitoreo detenido")
    }
    
    /// Verifica si hay cambios en el portapapeles
    private func checkClipboard() {
        let pasteboard = UIPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastPasteboardChangeCount {
            print("📍 Cambio detectado: \(lastPasteboardChangeCount) → \(currentChangeCount)")
            lastPasteboardChangeCount = currentChangeCount
            
            // Detectar tipo de contenido y agregar al histórico
            if let url = pasteboard.url {
                print("🔗 URL detectada")
                addToHistory(url.absoluteString, type: .url)
            } else if let image = pasteboard.image {
                print("🖼️ Imagen detectada")
                // Convertir imagen a base64 para persistencia
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let base64String = imageData.base64EncodedString()
                    addToHistory(base64String, type: .image)
                }
            } else if let text = pasteboard.string, !text.isEmpty {
                print("📝 Texto detectado: \(text.prefix(50))")
                addToHistory(text, type: .text)
            } else {
                print("⚠️ Sin contenido reconocible")
            }
        }
    }
    
    /// Obtiene una imagen de un item si es de tipo imagen
    func getImage(from item: ClipboardItem) -> UIImage? {
        guard item.type == .image else { return nil }
        
        if let data = Data(base64Encoded: item.content),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    /// Captura manualmente el contenido actual del portapapeles
    /// (para el botón Refresh en la UI)
    func captureCurrentClipboard() {
        print("📋 Capturando contenido actual del portapapeles...")
        let pasteboard = UIPasteboard.general
        
        // Detectar tipo de contenido y agregar al histórico
        if let url = pasteboard.url {
            addToHistory(url.absoluteString, type: .url)
        } else if let image = pasteboard.image {
            // Convertir imagen a base64 para persistencia
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                addToHistory(base64String, type: .image)
            }
        } else if let text = pasteboard.string, !text.isEmpty {
            addToHistory(text, type: .text)
        } else {
            print("⚠️ No hay contenido en el portapapeles")
        }
        
        // Actualizar changeCount para evitar duplicados
        lastPasteboardChangeCount = pasteboard.changeCount
    }
    
    // MARK: - History Management
    
    /// Agrega un item al histórico
    private func addToHistory(_ content: String, type: ClipboardItem.ContentType = .text) {
        // No agregar duplicados consecutivos
        if history.first?.content == content {
            return
        }
        
        let item = ClipboardItem(content: content, type: type)
        history.insert(item, at: 0)
        
        // Limitar al máximo
        if history.count > maxHistoryItems {
            history.removeLast(history.count - maxHistoryItems)
        }
        
        saveHistory()
        currentContent = content
        
        print("✅ Agregado al histórico: \(content.prefix(30))...")
    }
    
    /// Copia un item del histórico al portapapeles
    func copyToClipboard(_ item: ClipboardItem) {
        UIPasteboard.general.string = item.content
        currentContent = item.content
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
        print("✅ Copiado: \(item.content.prefix(30))...")
    }
    
    /// Limpia el histórico
    func clearHistory() {
        history.removeAll()
        saveHistory()
        print("🗑️ Histórico limpiado")
    }
    
    /// Elimina un item específico
    func removeItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(Array(history.prefix(maxHistoryItems)))
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Error guardando: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            history = []
            return
        }
        
        do {
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
            lastPasteboardChangeCount = UIPasteboard.general.changeCount
            print("✅ Histórico cargado: \(history.count) items")
        } catch {
            print("❌ Error cargando: \(error)")
            history = []
        }
    }
}
