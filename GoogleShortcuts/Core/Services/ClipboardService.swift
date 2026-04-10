import Foundation
import UIKit
import SwiftUI

/// Modelo para un item del portapapeles
public struct ClipboardItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let type: ContentType  // text, url, image description
    
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
    
    /// Formato legible del contenido (truncado si es muy largo)
    public var displayText: String {
        let maxLength = 100
        return content.count > maxLength
            ? String(content.prefix(maxLength)) + "..."
            : content
    }
    
    /// Tiempo relativo desde que se copió
    public var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Servicio centralizado para gestionar el portapapeles
@MainActor
final class ClipboardService: NSObject, ObservableObject {
    static let shared = ClipboardService()
    
    @Published var history: [ClipboardItem] = []
    @Published var currentContent: String = ""
    
    private var lastPasteboardChangeCount: Int = 0
    private var monitoringTimer: Timer?
    private let maxHistoryItems = 50  // Guardamos últimos 50 items
    private let userDefaultsKey = "clipboard_history"
    
    private override init() {
        super.init()
        loadHistory()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Inicia el monitoreo de cambios en el portapapeles
    private func startMonitoring() {
        // Chequear cada 0.5 segundos
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    /// Detiene el monitoreo
    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
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
            } else if let text = pasteboard.string {
                addToHistory(text, type: .text)
            }
        }
    }
    
    // MARK: - History Management
    
    /// Agrega un item al histórico
    private func addToHistory(_ content: String, type: ClipboardItem.ContentType = .text) {
        // No agregar duplicados consecutivos
        if history.first?.content == content {
            return
        }
        
        let item = ClipboardItem(content: content, type: type)
        history.insert(item, at: 0)  // Agregar al inicio
        
        // Limitar a maxHistoryItems
        if history.count > maxHistoryItems {
            history.removeLast(history.count - maxHistoryItems)
        }
        
        saveHistory()
        currentContent = content
    }
    
    /// Copia un item del histórico al portapapeles
    public func copyToClipboard(_ item: ClipboardItem) {
        UIPasteboard.general.string = item.content
        currentContent = item.content
    }
    
    /// Limpia el histórico completo
    public func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    /// Elimina un item específico del histórico
    public func removeItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    // MARK: - Persistence
    
    /// Guarda el histórico en UserDefaults
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history.prefix(maxHistoryItems))
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
