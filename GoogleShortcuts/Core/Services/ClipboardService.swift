import Foundation
import UIKit
import SwiftUI

/// Modelo para un item del portapapeles
public struct ClipboardItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let type: ContentType
    public let fileName: String?  // Para archivos
    public let fileSize: Int?      // Tamaño en bytes
    
    public enum ContentType: String, Codable, Sendable {
        case text
        case url
        case image
        case pdf
        case file
        case unknown
    }
    
    public init(content: String, type: ContentType = .text, fileName: String? = nil, fileSize: Int? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
        self.fileName = fileName
        self.fileSize = fileSize
    }
    
    public var displayText: String {
        switch type {
        case .file, .pdf:
            if let name = fileName {
                return "📁 \(name)"
            }
            return "📁 Archivo"
        case .image:
            return "🖼️ Imagen"
        case .url:
            return "🔗 URL"
        case .text, .unknown:
            let maxLength = 100
            return content.count > maxLength
                ? String(content.prefix(maxLength)) + "..."
                : content
        }
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
    private var lastCapturedText: String = ""
    private var lastCapturedURL: URL?
    private var monitoringTimer: Timer?
    private let maxHistoryItems = 50
    private let userDefaultsKey = "clipboard_history"
    private var checkClipboardCallCount = 0
    
    nonisolated private override init() {
        super.init()
    }
    
    // MARK: - Inicialización
    
    /// Inicializa el servicio (debe llamarse en MainActor)
    func initializeService() {
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
        print("📱 App en foreground - verificando portapapeles")
        // Resetear a -1 para forzar que ANY cambio sea detectado
        // Esto asegura que si el portapapeles cambió mientras estábamos en background, se detecte
        lastPasteboardChangeCount = -1
        // Iniciar/reiniciar monitoreo
        stopMonitoring()
        startMonitoring()
        // Verificar inmediatamente
        checkClipboard()
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 App en background - pausando monitoreo")
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Inicia el monitoreo del portapapeles
    func startMonitoring() {
        guard monitoringTimer == nil else {
            return
        }
        
        // Capturar estado inicial del portapapeles
        captureClipboardState()
        
        // Crear timer que monitorea cada 0.5 segundos
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        
        // Agregar a RunLoop.main explícitamente
        RunLoop.main.add(timer, forMode: .common)
        monitoringTimer = timer
    }
    
    /// Detiene el monitoreo
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// Captura el estado actual del portapapeles (contenido + changeCount)
    private func captureClipboardState() {
        let pasteboard = UIPasteboard.general
        lastPasteboardChangeCount = pasteboard.changeCount
        lastCapturedText = pasteboard.string ?? ""
        lastCapturedURL = pasteboard.url
    }
    
    /// Verifica si hay cambios en el portapapeles
    /// Accede directamente al contenido, similar a iOS Shortcuts
    func checkClipboard() {
        let pasteboard = UIPasteboard.general
        
        // Estrategia: Verificar cambios en contenido real, no solo changeCount
        // Esto es más robusto que confiar solo en changeCount que puede fallar después de tiempo
        
        var hasChanged = false
        
        // Verificar texto
        if let currentText = pasteboard.string, !currentText.isEmpty {
            if currentText != lastCapturedText && !isDuplicateInHistory(currentText) {
                lastCapturedText = currentText
                addToHistory(currentText, type: .text)
                hasChanged = true
            }
        }
        
        // Verificar URL
        if let currentURL = pasteboard.url {
            if currentURL != lastCapturedURL && !isDuplicateInHistory(currentURL.absoluteString) {
                lastCapturedURL = currentURL
                addToHistory(currentURL.absoluteString, type: .url)
                hasChanged = true
            }
        }
        
        // Verificar imagen
        if let image = pasteboard.image {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                if !isDuplicateInHistory(base64String) {
                    addToHistory(base64String, type: .image)
                    hasChanged = true
                }
            }
        }
        
        // Actualizar changeCount si hubo cambio
        if hasChanged {
            lastPasteboardChangeCount = pasteboard.changeCount
        }
    }
    
    /// Verifica si un contenido ya existe en el histórico
    private func isDuplicateInHistory(_ content: String) -> Bool {
        return history.first?.content == content
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
        }
        
        // Actualizar estado capturado
        captureClipboardState()
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
        // Desactivar temporalmente el monitoreo para evitar que se agregue al histórico
        stopMonitoring()
        
        // Copiar según el tipo
        if item.type == .image, let image = getImage(from: item) {
            // Para imágenes, copiar la imagen real, no la base64
            UIPasteboard.general.image = image
            print("✅ Imagen copiada al portapapeles")
        } else {
            // Para texto y URLs, copiar como string
            UIPasteboard.general.string = item.content
            print("✅ Copiado: \(item.content.prefix(30))...")
        }
        
        currentContent = item.content
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
        
        // Reanudar monitoreo después de un pequeño delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
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
