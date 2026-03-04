import Foundation

/// Cliente de Gmail API v1.
///
/// Encapsula todas las llamadas a la API de Gmail:
/// - Listar mensajes
/// - Obtener mensaje completo
/// - Enviar mensaje
/// - Buscar mensajes
///
/// Todas las llamadas requieren autenticación OAuth2 (manejada por HTTPClient).
actor GmailAPIClient {
    
    static let shared = GmailAPIClient()
    
    private let http = HTTPClient.shared
    private let baseURL = OAuthConfig.userEndpoint
    
    private init() {}
    
    // MARK: - List Messages
    
    /// Lista los mensajes del inbox.
    ///
    /// - Parameters:
    ///   - maxResults: Número máximo de mensajes (default: 20)
    ///   - query: Query de búsqueda en formato Gmail (ej: "is:unread", "subject:factura")
    ///   - pageToken: Token para paginación
    /// - Returns: Lista de emails parseados
    func listMessages(
        maxResults: Int = 20,
        query: String? = nil,
        pageToken: String? = nil
    ) async throws -> (emails: [Email], nextPageToken: String?) {
        var queryItems = [
            URLQueryItem(name: "maxResults", value: String(maxResults))
        ]
        
        if let query = query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        let listResponse: GmailMessageListResponse = try await http.authenticatedRequest(
            url: "\(baseURL)/messages",
            queryItems: queryItems,
            responseType: GmailMessageListResponse.self
        )
        
        guard let messageRefs = listResponse.messages, !messageRefs.isEmpty else {
            return (emails: [], nextPageToken: nil)
        }
        
        // Obtener detalle de cada mensaje en paralelo
        let emails = try await withThrowingTaskGroup(of: Email?.self, returning: [Email].self) { group in
            for ref in messageRefs {
                group.addTask {
                    try await self.getMessage(id: ref.id)
                }
            }
            
            var results: [Email] = []
            for try await email in group {
                if let email = email {
                    results.append(email)
                }
            }
            
            return results.sorted { $0.date > $1.date }
        }
        
        return (emails: emails, nextPageToken: listResponse.nextPageToken)
    }
    
    // MARK: - Get Single Message
    
    /// Obtiene un mensaje completo por ID.
    func getMessage(id: String) async throws -> Email? {
        let message: GmailMessage = try await http.authenticatedRequest(
            url: "\(baseURL)/messages/\(id)",
            queryItems: [
                URLQueryItem(name: "format", value: "full")
            ],
            responseType: GmailMessage.self
        )
        
        return message.toEmail()
    }
    
    // MARK: - Send Message
    
    /// Envía un correo electrónico.
    ///
    /// - Parameters:
    ///   - to: Dirección de destino
    ///   - subject: Asunto
    ///   - body: Cuerpo del mensaje (texto plano)
    ///   - from: Email del remitente (se obtiene automáticamente si es nil)
    /// - Returns: ID del mensaje enviado
    @discardableResult
    func sendMessage(
        to: String,
        subject: String,
        body: String,
        from: String? = nil
    ) async throws -> String {
        let senderEmail: String
        if let fromEmail = from {
            senderEmail = fromEmail
        } else {
            senderEmail = try await getSenderEmail()
        }
        
        let composition = EmailComposition(
            to: to,
            subject: subject,
            body: body,
            cc: nil,
            bcc: nil
        )
        
        let rawMessage = composition.toBase64URLEncoded(from: senderEmail)
        
        // Gmail API espera: { "raw": "base64url_encoded_message" }
        let sendBody = ["raw": rawMessage]
        let sendBodyData = try JSONEncoder().encode(sendBody)
        
        let response: GmailSendResponse = try await http.authenticatedRequest(
            url: "\(baseURL)/messages/send",
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: sendBodyData,
            responseType: GmailSendResponse.self
        )
        
        return response.id
    }
    
    // MARK: - Search Messages
    
    /// Busca correos usando la sintaxis de búsqueda de Gmail.
    ///
    /// Ejemplos de queries:
    /// - `"subject:factura"` → correos con "factura" en el asunto
    /// - `"from:banco@ejemplo.com"` → correos de un remitente
    /// - `"is:unread"` → correos no leídos
    /// - `"newer_than:1d"` → correos del último día
    /// - `"has:attachment"` → correos con adjuntos
    func searchMessages(
        query: String,
        maxResults: Int = 10
    ) async throws -> [Email] {
        let (emails, _) = try await listMessages(maxResults: maxResults, query: query)
        return emails
    }
    
    // MARK: - Check New Messages
    
    /// Verifica si hay mensajes nuevos no leídos.
    ///
    /// - Parameter since: Verificar desde esta fecha (default: últimas 24h)
    /// - Returns: Lista de correos no leídos recientes
    func checkNewMessages(since: Date? = nil) async throws -> [Email] {
        let sinceDate = since ?? Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        
        let timestamp = Int(sinceDate.timeIntervalSince1970)
        let query = "is:unread after:\(timestamp)"
        
        return try await searchMessages(query: query)
    }
    
    // MARK: - Unread Count
    
    /// Obtiene el número de correos no leídos en el inbox.
    func getUnreadCount() async throws -> Int {
        // Usar labels endpoint que es más eficiente
        struct LabelResponse: Codable {
            let messagesUnread: Int?
        }
        
        let response: LabelResponse = try await http.authenticatedRequest(
            url: "\(baseURL)/labels/INBOX",
            responseType: LabelResponse.self
        )
        
        return response.messagesUnread ?? 0
    }
    
    // MARK: - Profile
    
    /// Obtiene el email del usuario autenticado.
    func getSenderEmail() async throws -> String {
        struct ProfileResponse: Codable {
            let emailAddress: String
        }
        
        let profile: ProfileResponse = try await http.authenticatedRequest(
            url: "\(baseURL)/profile",
            responseType: ProfileResponse.self
        )
        
        return profile.emailAddress
    }
}
