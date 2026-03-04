import AppIntents
import Foundation

/// App Intent: Consultar los últimos correos recibidos.
///
/// Devuelve un resumen de los últimos N correos del inbox.
/// Útil para automatizaciones que necesitan procesar correos recientes.
///
/// ## Ejemplo en Shortcuts:
/// 1. "Consultar últimos correos" (máx: 5)
/// 2. "Repetir con cada uno" → Procesar cada correo
/// 3. "Si contiene 'factura'" → Enviar notificación
struct CheckRecentEmailsIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Consultar últimos correos"
    static var description = IntentDescription(
        "Obtiene los correos más recientes de tu inbox de Gmail.",
        categoryName: "Email"
    )
    
    @Parameter(
        title: "Cantidad",
        description: "Número de correos a obtener (1-20)",
        default: 5,
        controlStyle: .stepper,
        inclusiveRange: (1, 20)
    )
    var count: Int
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard (try? TokenStorage.shared.loadTokens()) != nil else {
            throw IntentError.notAuthenticated
        }
        
        let emails = try await EmailService.shared.getRecentEmails(
            count: count,
            forceRefresh: true
        )
        
        if emails.isEmpty {
            return .result(
                value: "No hay correos",
                dialog: "No se encontraron correos en tu inbox."
            )
        }
        
        // Formatear resultado como texto legible
        var summary = "📬 Últimos \(emails.count) correos:\n\n"
        
        for (index, email) in emails.enumerated() {
            let unreadMark = email.isUnread ? "🔵 " : ""
            summary += "\(index + 1). \(unreadMark)\(email.senderName)\n"
            summary += "   📌 \(email.subject)\n"
            summary += "   🕐 \(email.formattedDate)\n"
            if !email.snippet.isEmpty {
                let preview = String(email.snippet.prefix(80))
                summary += "   📝 \(preview)...\n"
            }
            summary += "\n"
        }
        
        return .result(
            value: summary,
            dialog: IntentDialog(stringLiteral: "Se encontraron \(emails.count) correos.")
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Obtener los últimos \(\.$count) correos")
    }
}

/// App Intent: Verificar si hay correos nuevos no leídos.
///
/// Diseñado para ser usado en automatizaciones periódicas:
/// - Shortcuts Automation: "Cada día a las 8:00 AM"
/// - Resultado: Lista de correos no leídos
///
/// ## Alternativa a Push Notifications:
/// Crear una automatización en Shortcuts:
/// 1. Trigger: "Hora del día" → cada 30 min (o la frecuencia deseada)
/// 2. Action: "Verificar correos nuevos" (este intent)
/// 3. Condicional: Si resultado contiene correos → Mostrar notificación
struct CheckNewEmailsIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Verificar correos nuevos"
    static var description = IntentDescription(
        "Comprueba si hay correos nuevos sin leer en tu inbox.",
        categoryName: "Email"
    )
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard (try? TokenStorage.shared.loadTokens()) != nil else {
            throw IntentError.notAuthenticated
        }
        
        let newEmails = try await EmailService.shared.checkNewEmails()
        
        if newEmails.isEmpty {
            return .result(
                value: "0",
                dialog: "No hay correos nuevos. ✅"
            )
        }
        
        var summary = "📬 \(newEmails.count) correo(s) nuevo(s):\n\n"
        
        for email in newEmails.prefix(5) {
            summary += "• \(email.senderName): \(email.subject)\n"
        }
        
        if newEmails.count > 5 {
            summary += "\n... y \(newEmails.count - 5) más"
        }
        
        return .result(
            value: summary,
            dialog: IntentDialog(stringLiteral: "Tienes \(newEmails.count) correo(s) nuevo(s).")
        )
    }
}

/// App Intent: Contar correos no leídos.
///
/// Devuelve solo el número, ideal para widgets o condiciones en Shortcuts.
struct UnreadCountIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Contar correos no leídos"
    static var description = IntentDescription(
        "Obtiene el número de correos no leídos en tu inbox.",
        categoryName: "Email"
    )
    
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        guard (try? TokenStorage.shared.loadTokens()) != nil else {
            throw IntentError.notAuthenticated
        }
        
        let count = try await EmailService.shared.getUnreadCount()
        
        let message = count == 0
            ? "No tienes correos sin leer. ✅"
            : "Tienes \(count) correo(s) sin leer."
        
        return .result(
            value: count,
            dialog: IntentDialog(stringLiteral: message)
        )
    }
}

/// App Intent: Consultar correos Gmail.
///
/// Devuelve un resumen de los últimos N correos del inbox.
/// Útil para automatizaciones que necesitan procesar correos recientes.
///
/// ## Ejemplo en Shortcuts:
/// 1. "Consultar últimos correos" (máx: 5)
/// 2. "Repetir con cada uno" → Procesar cada correo
/// 3. "Si contiene 'factura'" → Enviar notificación
struct CheckEmailIntent: AppIntent {
    static var title: LocalizedStringResource = "Consultar correos Gmail"
    static var description: IntentDescription = "Consulta los últimos correos recibidos en Gmail"
    
    @Parameter(title: "Cantidad", default: 5)
    var count: Int
    
    @Parameter(title: "Solo no leídos", default: false)
    var unreadOnly: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Consultar últimos \(\.$count) correos") {
            \.$unreadOnly
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard (try? TokenStorage.shared.loadTokens()) != nil else {
            return .result(value: "❌ No estás autenticado. Abre GoogleShortcuts e inicia sesión.")
        }
        
        do {
            let emails: [Email]
            if unreadOnly {
                emails = try await EmailService.shared.searchEmails(query: "is:unread", maxResults: count)
            } else {
                emails = try await EmailService.shared.getRecentEmails(count: count)
            }
            
            if emails.isEmpty {
                return .result(value: unreadOnly ? "No tienes correos sin leer" : "No se encontraron correos")
            }
            
            let summary = emails.map { email in
                "• De: \(email.from)\n  Asunto: \(email.subject)"
            }.joined(separator: "\n\n")
            
            let label = unreadOnly ? "no leídos" : "recientes"
            return .result(value: "📧 \(emails.count) correo(s) \(label):\n\n\(summary)")
        } catch {
            return .result(value: "❌ Error: \(error.localizedDescription)")
        }
    }
}
