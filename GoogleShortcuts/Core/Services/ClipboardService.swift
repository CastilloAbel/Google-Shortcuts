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
/// Monitorea automáticamente los cambios en el portapapeles
final class ClipboardService: NSObject, ObservableObject {
    static let shared = ClipboardService()
    
    @Published var history: [ClipboardItem] = []
    @Published var currentContent: String = ""
    
    private var lastPasteboardChangeCount: Int = 0
    private var monitoringTimer: Timer?
    private let maxHistoryItems = 50
    private let userDefaultsKey = "clipboard_history"
    
    private override init() {
        super.init()
        loadHistory()
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Monitoring Setup
    
    /// Configura y inicia el monitoreo de portapapeles
    private func setupMonitoring() {
        // Iniciar monitoreo inmediatamente
        startMonitoring()
        
        // Pausar cuando la app entra en background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Reanudar cuando regresa a foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterForeground() {
        print("📱 App en foreground - reanudando monitoreo de clipboard")
        startMonitoring()
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App en background - pausando monitoreo de clipboard")
        stopMonitoring()
    }
    
    /// Inicia el monitoreo de cambios en el portapapeles
    private func startMonitoring() {
        guard monitoringTimer == nil else { return }
        
        // Inicializar estado actual
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
        
        // Chequear cada 0.5 segundos
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        print("✅ Monitoreo de clipboard INICIADO")
    }
    
    /// Detiene el monitoreo
    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("⏸️ Monitoreo de clipboard PAUSADO")
    }
    
    /// Verifica si hay cambios en el portapapeles
    private func checkClipboard() {
        let pasteboard = UIPasteboard.general
        
        // Si el changeCount cambió, hay contenido nuevo
        if pasteboard.changeCount != lastPasteboardChangeCount {
            lastPasteboardChangeCount = pasteboard.changeCount
            
            // Prioridad: URL > Imagen > Texto
            if let url = pasteboard.url {
                addToHistory(url.absoluteString, type: .url)
            } else if pasteboard.image != nil {
                addToHistory("[Imagen copiada]", type: .image)
            } else if let text = pasteboard.string, !text.isEmpty {
                addToHistory(text, type: .text)
            }
        }
    }
    
    // MARK: - History Management
    
    /// Agrega un item al histórico (thread-safe)
    private func addToHistory(_ content: String, type: ClipboardItem.ContentType = .text) {
        DispatchQueue.main.async {
            // No agregar duplicados consecutivos
            if self.history.first?.content == content {
                return
            }
            
            let item = ClipboardItem(content: content, type: type)
            self.history.insert(item, at: 0)
            
            // Limitar a maxHistoryItems
            if self.history.count > self.maxHistoryItems {
                self.history.removeLast(self.history.count - self.maxHistoryItems)
            }
            
            self.saveHistory()
            self.currentContent = content
            
            print("📝 Item agregado al histórico: \(content.prefix(30))...")
        }
    }
    
    /// Copia un item del histórico al portapapeles (thread-safe)
    public func copyToClipboard(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            UIPasteboard.general.string = item.content
            self.currentContent = item.content
            self.lastPasteboardChangeCount = UIPasteboard.general.changeCount
            print("✅ Copiado al portapapeles: \(item.content.prefix(30))...")
        }
    }
    
    /// Limpia el histórico completo (thread-safe)
    public func clearHistory() {
        DispatchQueue.main.async {
            self.history.removeAll()
            self.saveHistory()
            print("🗑️ Histórico de portapapeles limpiado")
        }
    }
    
    /// Elimina un item específico del histórico (thread-safe)
    public func removeItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.history.removeAll { $0.id == item.id }
            self.saveHistory()
        }
    }
    
    // MARK: - Persistence
    
    /// Guarda el histórico en UserDefaults
    private func saveHistory() {
        do {
            let dataToSave = Array(history.prefix(maxHistoryItems))
            let data = try JSONEncoder().encode(dataToSave)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("[Clipboard] Error guardando histórico: \(error)")
        }
    }
    
    /// Carga el histórico desde UserDefaults
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            history = []
            return
        }
        
        do {
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
            lastPasteboardChangeCount = UIPasteboard.general.changeCount
        } catch {
            print("[Clipboard] Error cargando histórico: \(error)")
            history = []
        }
    }
}
