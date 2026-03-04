import Foundation

// MARK: - Email Model

/// Modelo de email simplificado para la app.
/// Representa un correo de Gmail con los campos esenciales.
struct Email: Identifiable, Codable, Hashable {
    let id: String          // Gmail message ID
    let threadId: String
    let from: String
    let to: String
    let subject: String
    let snippet: String     // Preview del cuerpo (texto plano)
    let body: String        // Cuerpo completo (texto plano)
    let date: Date
    let isUnread: Bool
    let labels: [String]
    
    /// Formato legible de la fecha.
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Nombre del remitente (sin email).
    var senderName: String {
        if let name = from.split(separator: "<").first?.trimmingCharacters(in: .whitespaces),
           !name.isEmpty {
            return name
        }
        return from
    }
}

// MARK: - Email Composition

/// Modelo para componer un email.
struct EmailComposition {
    let to: String
    let subject: String
    let body: String
    let cc: String?
    let bcc: String?
    
    /// Construye el body RFC 2822 para enviar via Gmail API.
    /// Gmail API espera el mensaje en formato MIME codificado en Base64URL.
    func toRawMIME(from senderEmail: String) -> String {
        var message = ""
        message += "From: \(senderEmail)\r\n"
        message += "To: \(to)\r\n"
        if let cc = cc, !cc.isEmpty {
            message += "Cc: \(cc)\r\n"
        }
        if let bcc = bcc, !bcc.isEmpty {
            message += "Bcc: \(bcc)\r\n"
        }
        message += "Subject: \(subject)\r\n"
        message += "Content-Type: text/plain; charset=utf-8\r\n"
        message += "\r\n"
        message += body
        
        return message
    }
    
    /// Codifica el mensaje MIME en Base64URL (formato requerido por Gmail API).
    func toBase64URLEncoded(from senderEmail: String) -> String {
        let raw = toRawMIME(from: senderEmail)
        return Data(raw.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Gmail API Response Models

/// Respuesta de la API al listar mensajes.
struct GmailMessageListResponse: Codable {
    let messages: [GmailMessageRef]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?
}

/// Referencia a un mensaje (solo IDs).
struct GmailMessageRef: Codable {
    let id: String
    let threadId: String
}

/// Mensaje completo de Gmail API.
struct GmailMessage: Codable {
    let id: String
    let threadId: String
    let labelIds: [String]?
    let snippet: String?
    let payload: GmailPayload?
    let internalDate: String?
}

/// Payload del mensaje.
struct GmailPayload: Codable {
    let headers: [GmailHeader]?
    let body: GmailBody?
    let parts: [GmailPart]?
    let mimeType: String?
}

/// Header del mensaje.
struct GmailHeader: Codable {
    let name: String
    let value: String
}

/// Body del mensaje.
struct GmailBody: Codable {
    let size: Int?
    let data: String?  // Base64URL encoded
}

/// Parte MIME del mensaje (para emails multipart).
struct GmailPart: Codable {
    let mimeType: String?
    let body: GmailBody?
    let parts: [GmailPart]?
}

/// Respuesta al enviar un mensaje.
struct GmailSendResponse: Codable {
    let id: String
    let threadId: String
    let labelIds: [String]?
}

// MARK: - Gmail API Error

struct GmailAPIError: Codable {
    let error: GmailErrorDetail
}

struct GmailErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String?
}

// MARK: - Parsing Helpers

extension GmailMessage {
    
    /// Convierte un GmailMessage (API) a nuestro modelo Email.
    func toEmail() -> Email {
        let headers = payload?.headers ?? []
        
        let from = headers.first(where: { $0.name.lowercased() == "from" })?.value ?? "Desconocido"
        let to = headers.first(where: { $0.name.lowercased() == "to" })?.value ?? ""
        let subject = headers.first(where: { $0.name.lowercased() == "subject" })?.value ?? "(Sin asunto)"
        let dateStr = headers.first(where: { $0.name.lowercased() == "date" })?.value
        
        // Parse date
        let date: Date
        if let internalDate = internalDate, let ms = Double(internalDate) {
            date = Date(timeIntervalSince1970: ms / 1000)
        } else if let dateStr = dateStr {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            date = formatter.date(from: dateStr) ?? Date()
        } else {
            date = Date()
        }
        
        // Extract body text
        let body = extractTextBody()
        
        let isUnread = labelIds?.contains("UNREAD") ?? false
        
        return Email(
            id: id,
            threadId: threadId,
            from: from,
            to: to,
            subject: subject,
            snippet: snippet ?? "",
            body: body,
            date: date,
            isUnread: isUnread,
            labels: labelIds ?? []
        )
    }
    
    /// Extrae el texto plano del cuerpo del mensaje.
    private func extractTextBody() -> String {
        // Intentar obtener text/plain del body directo
        if let data = payload?.body?.data, !data.isEmpty {
            return decodeBase64URL(data)
        }
        
        // Buscar en parts (mensajes multipart)
        if let parts = payload?.parts {
            return extractTextFromParts(parts)
        }
        
        return snippet ?? ""
    }
    
    /// Busca recursivamente text/plain en las partes MIME.
    private func extractTextFromParts(_ parts: [GmailPart]) -> String {
        for part in parts {
            if part.mimeType == "text/plain", let data = part.body?.data {
                return decodeBase64URL(data)
            }
            if let subParts = part.parts {
                let result = extractTextFromParts(subParts)
                if !result.isEmpty { return result }
            }
        }
        return ""
    }
    
    /// Decodifica Base64URL a texto.
    private func decodeBase64URL(_ base64url: String) -> String {
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return text
    }
}
