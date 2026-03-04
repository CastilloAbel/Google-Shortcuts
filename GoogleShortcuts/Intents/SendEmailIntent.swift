import AppIntents
import Foundation

struct SendEmailIntent: AppIntent {
    static var title: LocalizedStringResource = "Enviar correo Gmail"
    static var description: IntentDescription = "Envía un correo electrónico usando tu cuenta de Gmail"
    
    @Parameter(title: "Destinatario", description: "Dirección de correo del destinatario")
    var recipient: String
    
    @Parameter(title: "Asunto", description: "Asunto del correo")
    var subject: String
    
    @Parameter(title: "Cuerpo", description: "Contenido del correo")
    var body: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Enviar correo a \(\.$recipient) con asunto \(\.$subject)")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Verificar autenticación
        guard let tokens = try? TokenStorage.shared.loadTokens() else {
            return .result(value: "❌ Error: No estás autenticado. Abre GoogleShortcuts e inicia sesión.")
        }
        
        // Verificar que el token no esté expirado sin posibilidad de refresh
        if tokens.isExpired {
            do {
                _ = try await TokenStorage.shared.refreshAccessToken()
            } catch {
                return .result(value: "❌ Error: Token expirado. Abre GoogleShortcuts para renovar la sesión.")
            }
        }
        
        do {
            let emailService = EmailService.shared
            _ = try await emailService.sendEmail(to: recipient, subject: subject, body: body)
            return .result(value: "✅ Correo enviado a \(recipient)")
        } catch {
            return .result(value: "❌ Error al enviar: \(error.localizedDescription)")
        }
    }
}
