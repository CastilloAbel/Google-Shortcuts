import Foundation

/// Configuración OAuth2 para Google Gmail API.
///
/// IMPORTANTE: Debes reemplazar `clientID` con el Client ID obtenido
/// de Google Cloud Console. Ver docs/OAUTH_SETUP.md para instrucciones.
///
/// Flujo: OAuth2 Authorization Code + PKCE (sin client secret en iOS).
/// Google recomienda PKCE para apps móviles (públicas).
enum OAuthConfig {
    
    // MARK: - Google Cloud Console Credentials
    
    /// Client ID de tipo "iOS" creado en Google Cloud Console.
    /// Formato: XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com
    ///
    /// ⚠️ REEMPLAZAR con tu Client ID real.
    static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
    
    /// Redirect URI registrada en Google Cloud Console.
    /// Para apps iOS, Google usa el scheme reverso del Client ID.
    /// Formato: com.googleusercontent.apps.YOUR_CLIENT_ID:/oauthredirect
    ///
    /// Este scheme debe coincidir con el registrado en Info.plist > CFBundleURLSchemes
    static var redirectURI: String {
        let reversed = clientID
            .replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        return "com.googleusercontent.apps.\(reversed):/oauthredirect"
    }
    
    // MARK: - OAuth2 Endpoints
    
    /// Authorization endpoint de Google.
    static let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    
    /// Token endpoint de Google.
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    
    /// Revocation endpoint.
    static let revocationEndpoint = "https://oauth2.googleapis.com/revoke"
    
    // MARK: - Scopes
    
    /// Scopes de Gmail que necesitamos.
    ///
    /// - `gmail.send`: Enviar correos
    /// - `gmail.readonly`: Leer correos (listar, buscar)
    /// - `gmail.labels`: Acceder a etiquetas (opcional)
    ///
    /// NOTA: Mientras tu app esté en modo "Testing" en Google Cloud Console,
    /// solo los emails que agregues como "Test users" podrán autenticarse.
    static let scopes: [String] = [
        "https://www.googleapis.com/auth/gmail.send",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/userinfo.email"
    ]
    
    /// Scopes concatenados con espacio (formato requerido por OAuth2).
    static var scopeString: String {
        scopes.joined(separator: " ")
    }
    
    // MARK: - Gmail API
    
    /// Base URL de Gmail API v1.
    static let gmailAPIBase = "https://gmail.googleapis.com/gmail/v1"
    
    /// Endpoint para el usuario autenticado.
    static let userEndpoint = "\(gmailAPIBase)/users/me"
    
    // MARK: - Keychain & Storage
    
    /// Prefijo para almacenar tokens en Keychain.
    static let keychainService = "com.personal.googleshortcuts.oauth"
    
    /// Clave para el access token.
    static let accessTokenKey = "access_token"
    
    /// Clave para el refresh token.
    static let refreshTokenKey = "refresh_token"
    
    /// Clave para la fecha de expiración.
    static let expirationKey = "token_expiration"
    
    /// App Group para compartir datos con extensiones (App Intents).
    static let appGroupID = "group.com.personal.googleshortcuts"
}
