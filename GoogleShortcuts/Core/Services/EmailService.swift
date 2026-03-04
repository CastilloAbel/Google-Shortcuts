import Foundation

/// Servicio de alto nivel para operaciones de email.
///
/// Actúa como fachada sobre GmailAPIClient, proporcionando
/// una interfaz simplificada para los App Intents y la UI.
///
/// ## Responsabilidades:
/// - Enviar correos
/// - Listar últimos correos
/// - Buscar correos por criterios
/// - Verificar correos nuevos
/// - Cachear resultados para reducir llamadas API
actor EmailService {
    
    static let shared = EmailService()
    
    private let gmail = GmailAPIClient.shared
    
    /// Cache simple de emails (evita llamadas API repetidas).
    private var cachedEmails: [Email] = []
    private var lastFetchDate: Date?
    private let cacheValiditySeconds: TimeInterval = 60 // 1 minuto
    
    private init() {}
    
    // MARK: - Send Email
    
    /// Envía un correo electrónico.
    ///
    /// - Parameters:
    ///   - to: Dirección de destino
    ///   - subject: Asunto del correo
    ///   - body: Cuerpo del correo (texto plano)
    /// - Returns: ID del mensaje enviado en Gmail
    /// - Throws: Error si no hay autenticación o falla la API
    func sendEmail(to: String, subject: String, body: String) async throws -> String {
        guard !to.isEmpty else {
            throw EmailServiceError.invalidRecipient
        }
        guard !subject.isEmpty else {
            throw EmailServiceError.emptySubject
        }
        
        let messageId = try await gmail.sendMessage(
            to: to,
            subject: subject,
            body: body
        )
        
        return messageId
    }
    
    // MARK: - Fetch Emails
    
    /// Obtiene los últimos correos del inbox.
    ///
    /// - Parameter count: Número de correos a obtener (máx 50)
    /// - Parameter forceRefresh: Ignorar cache
    /// - Returns: Lista de emails ordenados por fecha descendente
    func getRecentEmails(count: Int = 20, forceRefresh: Bool = false) async throws -> [Email] {
        // Verificar cache
        if !forceRefresh,
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheValiditySeconds,
           !cachedEmails.isEmpty {
            return Array(cachedEmails.prefix(count))
        }
        
        let result = try await gmail.listMessages(maxResults: min(count, 50))
        
        cachedEmails = result.emails
        lastFetchDate = Date()
        
        return result.emails
    }
    
    // MARK: - Search
    
    /// Busca correos por consulta.
    ///
    /// - Parameters:
    ///   - query: Consulta de búsqueda (ej. "is:unread")
    ///   - maxResults: Máximo de resultados
    /// - Returns: Correos que coinciden
    func searchEmails(query: String, maxResults: Int = 20) async throws -> [Email] {
        guard !query.isEmpty else {
            throw EmailServiceError.emptySearchQuery
        }
        
        let result = try await gmail.listMessages(maxResults: maxResults, query: query)
        return result.emails
    }
    
    /// Busca correos por asunto.
    ///
    /// - Parameter subject: Texto a buscar en el asunto
    /// - Returns: Correos que coinciden
    func searchBySubject(_ subject: String) async throws -> [Email] {
        guard !subject.isEmpty else {
            throw EmailServiceError.emptySearchQuery
        }
        
        return try await gmail.searchMessages(
            query: "subject:\(subject)",
            maxResults: 20
        )
    }
    
    /// Busca correos por remitente.
    func searchByFrom(_ from: String) async throws -> [Email] {
        return try await gmail.searchMessages(
            query: "from:\(from)",
            maxResults: 20
        )
    }
    
    /// Búsqueda libre con sintaxis de Gmail.
    func search(query: String) async throws -> [Email] {
        return try await gmail.searchMessages(query: query)
    }
    
    // MARK: - Check New Emails
    
    /// Verifica si hay correos no leídos nuevos.
    ///
    /// - Returns: Correos no leídos recientes
    func checkNewEmails() async throws -> [Email] {
        return try await gmail.checkNewMessages()
    }
    
    /// Obtiene el conteo de correos no leídos.
    func getUnreadCount() async throws -> Int {
        return try await gmail.getUnreadCount()
    }
    
    // MARK: - Cache Management
    
    /// Invalida el cache de emails.
    func invalidateCache() {
        cachedEmails = []
        lastFetchDate = nil
    }
}

// MARK: - Errors

enum EmailServiceError: LocalizedError {
    case invalidRecipient
    case emptySubject
    case emptySearchQuery
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidRecipient:
            return "Dirección de correo inválida."
        case .emptySubject:
            return "El asunto no puede estar vacío."
        case .emptySearchQuery:
            return "La búsqueda no puede estar vacía."
        case .notAuthenticated:
            return "No has iniciado sesión. Abre la app y conecta tu cuenta de Google."
        }
    }
}
