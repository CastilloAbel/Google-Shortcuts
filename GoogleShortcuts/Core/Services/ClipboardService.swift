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
        print("📱 App en foreground - sincronizando portapapeles")
        // Detener antes de reiniciar
        stopMonitoring()
        // Sincronizar el estado ACTUAL del portapapeles
        // Esto previene falsos positivos de cambios
        captureClipboardState()
        // Iniciar monitoreo - que usará el estado recién sincronizado
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
            return
        }
        
        // Capturar estado inicial del portapapeles
        captureClipboardState()
        
        // Crear timer que monitorea cada 5 segundos (no 0.5)
        // Acceder frecuentemente al pasteboard causa notificaciones del sistema constantemente
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
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
    /// Estrategia: Chequear changeCount PRIMERO, solo leer contenido si cambió
    func checkClipboard() {
        let pasteboard = UIPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // OPTIMIZACIÓN: Si el changeCount no cambió, no hay nada nuevo
        if currentChangeCount == lastPasteboardChangeCount {
            return
        }
        
        // Solo si el changeCount cambió, leer el contenido
        let currentText = pasteboard.string ?? ""
        let currentURL = pasteboard.url
        let currentImage = pasteboard.image
        
        var detectado = false
        
        // Deduplicación: chequear contra los últimos 3 items
        let recentContent = Set(history.prefix(3).map { $0.content })
        
        // Verificar texto: solo agregar si es diferente del último capturado Y no en histórico
        if !currentText.isEmpty && currentText != lastCapturedText {
            if !recentContent.contains(currentText) {
                addToHistory(currentText, type: .text)
                detectado = true
            }
            lastCapturedText = currentText
        } else if !lastCapturedText.isEmpty && currentText.isEmpty {
            lastCapturedText = ""
        }
        
        // Verificar URL: solo agregar si es diferente Y no en histórico
        if let currentURL = currentURL, currentURL != lastCapturedURL {
            let urlString = currentURL.absoluteString
            if !recentContent.contains(urlString) {
                addToHistory(urlString, type: .url)
                detectado = true
            }
            lastCapturedURL = currentURL
        } else if currentURL == nil && lastCapturedURL != nil {
            lastCapturedURL = nil
        }
        
        // Verificar imagen
        if let currentImage = currentImage {
            if let imageData = currentImage.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                if !recentContent.contains(base64String) {
                    addToHistory(base64String, type: .image)
                    detectado = true
                }
            }
        }
        
        // Solo actualizar lastPasteboardChangeCount si hubo cambio real
        if detectado {
            lastPasteboardChangeCount = currentChangeCount
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
    /// (para el botón Refresh en la UI y auto-refresh en app launch)
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
    
    /// Verifica y captura el clipboard en app startup
    /// Solo captura si hay contenido nuevo (no duplicado)
    func refreshClipboardOnAppLaunch() {
        let pasteboard = UIPasteboard.general
        
        // Evitar agregar si el portapapeles no tiene nada
        guard let url = pasteboard.url ?? (pasteboard.string.map { $0 }) ?? pasteboard.image else {
            return
        }
        
        // Solo capturar si no está ya en los primeros 3 items
        let recentContent = Set(history.prefix(3).map { $0.content })
        
        if let text = pasteboard.string, !text.isEmpty, !recentContent.contains(text) {
            addToHistory(text, type: .text)
        } else if let url = pasteboard.url, !recentContent.contains(url.absoluteString) {
            addToHistory(url.absoluteString, type: .url)
        } else if let image = pasteboard.image {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                if !recentContent.contains(base64String) {
                    addToHistory(base64String, type: .image)
                }
            }
        }
        
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
