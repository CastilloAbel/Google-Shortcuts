import AppIntents

/// App Intent: Enviar correo electrónico via Gmail.
///
/// ## Uso en Shortcuts:
/// 1. Abrir app Shortcuts
/// 2. Crear nuevo shortcut
/// 3. Buscar "Enviar correo con GmailShortcuts"
/// 4. Configurar destinatario, asunto y cuerpo
/// 5. Ejecutar
///
/// ## Parámetros dinámicos:
/// Todos los parámetros son configurables desde Shortcuts.
/// Se pueden usar variables de Shortcuts (ej: texto del portapapeles,
/// resultado de otra acción, etc.)
///
/// ## Ejemplo de automatización:
/// Trigger: "Cuando abro la app Notas"
/// Action: "Enviar correo con GmailShortcuts"
///   - To: "mi-jefe@empresa.com"
///   - Subject: "Nota rápida"
///   - Body: [Contenido del portapapeles]
struct SendEmailIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Enviar correo con Gmail"
    static var description = IntentDescription(
        "Envía un correo electrónico usando tu cuenta de Gmail.",
        categoryName: "Email"
    )
    
    // MARK: - Parameters
    
    @Parameter(
        title: "Destinatario",
        description: "Dirección de correo del destinatario",
        requestValueDialog: "¿A quién quieres enviar el correo?"
    )
    var to: String
    
    @Parameter(
        title: "Asunto",
        description: "Asunto del correo",
        requestValueDialog: "¿Cuál es el asunto del correo?"
    )
    var subject: String
    
    @Parameter(
        title: "Cuerpo",
        description: "Contenido del correo (texto plano)",
        requestValueDialog: "¿Qué quieres escribir en el correo?",
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var body: String
    
    // MARK: - Execution
    
    /// Ejecuta el intent: envía el correo via Gmail API.
    ///
    /// - Returns: Resultado con confirmación y ID del mensaje
    /// - Throws: Error si no hay autenticación o falla el envío
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Verificar autenticación
        guard let tokens = try? await TokenStorage.shared.loadTokens(), tokens != nil else {
            throw IntentError.notAuthenticated
        }
        
        let messageId = try await EmailService.shared.sendEmail(
            to: to,
            subject: subject,
            body: body
        )
        
        let confirmationMessage = "✅ Correo enviado a \(to) con asunto \"\(subject)\""
        
        return .result(
            value: messageId,
            dialog: IntentDialog(stringLiteral: confirmationMessage)
        )
    }
    
    // MARK: - Opening App
    
    /// Si no hay autenticación, abre la app para que el usuario inicie sesión.
    static var openAppWhenRun: Bool = false
    
    /// Parametrización con resumen visual en Shortcuts.
    static var parameterSummary: some ParameterSummary {
        Summary("Enviar correo a \(\.$to) con asunto \(\.$subject)") {
            \.$body
        }
    }
}

// MARK: - Intent Errors

enum IntentError: LocalizedError {
    case notAuthenticated
    case invalidParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No has iniciado sesión. Abre GmailShortcuts e inicia sesión con Google."
        case .invalidParameter(let param):
            return "Parámetro inválido: \(param)"
        }
    }
}
