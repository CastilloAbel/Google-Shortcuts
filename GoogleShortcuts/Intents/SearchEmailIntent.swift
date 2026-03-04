import AppIntents

/// App Intent: Buscar correos por asunto o texto.
///
/// Usa la sintaxis de búsqueda de Gmail internamente.
/// El usuario solo necesita escribir texto y el intent construye el query.
///
/// ## Sintaxis de búsqueda soportada:
/// - Texto simple: busca en asunto, cuerpo y remitente
/// - "subject:factura" → solo en asunto
/// - "from:banco@example.com" → solo de un remitente
/// - "is:unread" → solo no leídos
/// - "has:attachment" → con adjuntos
/// - "newer_than:2d" → últimos 2 días
///
/// ## Ejemplo en Shortcuts:
/// 1. "Buscar correos" → texto: "factura"
/// 2. "Repetir con cada uno"
/// 3. "Agregar a Recordatorios" → crear tarea por cada factura
struct SearchEmailsIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Buscar correos en Gmail"
    static var description = IntentDescription(
        "Busca correos en tu inbox de Gmail por texto, asunto o remitente.",
        categoryName: "Email"
    )
    
    // MARK: - Parameters
    
    @Parameter(
        title: "Texto de búsqueda",
        description: "Texto a buscar (funciona con sintaxis de Gmail: subject:, from:, is:unread, etc.)",
        requestValueDialog: "¿Qué quieres buscar?"
    )
    var query: String
    
    @Parameter(
        title: "Máximo de resultados",
        description: "Número máximo de correos a devolver",
        default: 10,
        controlStyle: .stepper,
        inclusiveRange: (1, 50)
    )
    var maxResults: Int
    
    @Parameter(
        title: "Buscar en",
        description: "Dónde buscar el texto",
        default: .everywhere
    )
    var searchIn: SearchScope
    
    // MARK: - Execution
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard (try? TokenStorage.shared.loadTokens()) != nil else {
            throw IntentError.notAuthenticated
        }
        
        // Construir query según el scope
        let gmailQuery: String
        switch searchIn {
        case .everywhere:
            gmailQuery = query
        case .subject:
            gmailQuery = "subject:\(query)"
        case .sender:
            gmailQuery = "from:\(query)"
        }
        
        let emails = try await EmailService.shared.search(query: gmailQuery)
        let limited = Array(emails.prefix(maxResults))
        
        if limited.isEmpty {
            return .result(
                value: "Sin resultados",
                dialog: "No se encontraron correos para \"\(query)\"."
            )
        }
        
        var summary = "🔍 \(limited.count) resultado(s) para \"\(query)\":\n\n"
        
        for (index, email) in limited.enumerated() {
            summary += "\(index + 1). \(email.senderName)\n"
            summary += "   📌 \(email.subject)\n"
            summary += "   🕐 \(email.formattedDate)\n\n"
        }
        
        return .result(
            value: summary,
            dialog: IntentDialog(stringLiteral: "Se encontraron \(limited.count) correo(s).")
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Buscar \(\.$query) en \(\.$searchIn)") {
            \.$maxResults
        }
    }
}

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notAuthenticated
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthenticated:
            return "No estás autenticado. Abre la app e inicia sesión."
        }
    }
}

// MARK: - Search Scope Enum

/// Ámbito de búsqueda para el intent de búsqueda.
enum SearchScope: String, AppEnum {
    case everywhere = "everywhere"
    case subject = "subject"
    case sender = "sender"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Ámbito de búsqueda"
    }
    
    static var caseDisplayRepresentations: [SearchScope: DisplayRepresentation] {
        [
            .everywhere: "Todo el correo",
            .subject: "Solo en asunto",
            .sender: "Solo por remitente"
        ]
    }
}
