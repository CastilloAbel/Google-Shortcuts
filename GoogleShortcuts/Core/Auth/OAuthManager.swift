import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI

/// Manager principal de autenticación OAuth2 con Google.
///
/// Implementa el flujo OAuth2 Authorization Code con PKCE:
/// 1. Genera code_verifier y code_challenge
/// 2. Abre el navegador del sistema para login de Google
/// 3. Recibe el authorization code via URL Scheme callback
/// 4. Intercambia el code por access_token + refresh_token
///
/// ## ¿Por qué PKCE?
/// Las apps móviles son "clientes públicos" — no pueden guardar un client_secret
/// de forma segura. PKCE protege el flujo sin necesidad de secret.
///
/// ## Persistencia con Sideloading:
/// Los tokens se guardan en Keychain, que persiste al re-firmar cada 7 días.
/// El usuario NO necesita re-autenticarse al renovar la firma.
@MainActor
class OAuthManager: ObservableObject {
    
    static let shared = OAuthManager()
    
    // MARK: - Published State
    
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - PKCE State
    
    /// Code verifier para PKCE (se genera en cada intento de login).
    private var codeVerifier: String?
    
    // MARK: - Init
    
    private init() {
        // Verificar si hay tokens guardados al iniciar
        Task {
            await checkExistingAuth()
        }
    }
    
    /// Verifica si hay una sesión previa válida.
    private func checkExistingAuth() async {
        do {
            let tokens = try TokenStorage.shared.loadTokens()
            if tokens != nil {
                isAuthenticated = true
                await fetchUserEmail()
            }
        } catch {
            isAuthenticated = false
        }
    }
    
    // MARK: - Login Flow
    
    /// Inicia el flujo de autenticación OAuth2 con Google.
    ///
    /// Abre Safari/navegador in-app para que el usuario autorice la app.
    /// Después del login, Google redirige a nuestro URL Scheme con el authorization code.
    func startLogin() {
        isLoading = true
        error = nil
        
        // 1. Generar PKCE pair
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)
        
        // 2. Construir la URL de autorización
        var components = URLComponents(string: OAuthConfig.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: OAuthConfig.scopeString),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            // access_type=offline → nos da refresh_token
            URLQueryItem(name: "access_type", value: "offline"),
            // prompt=consent → fuerza pantalla de consentimiento (necesario para refresh_token)
            URLQueryItem(name: "prompt", value: "consent"),
            // state → protección contra CSRF
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        guard let url = components.url else {
            error = "Error al construir URL de autorización"
            isLoading = false
            return
        }
        
        // 3. Abrir en el navegador del sistema
        // Usamos UIApplication.shared.open porque ASWebAuthenticationSession
        // requiere un presentationContextProvider que puede dar problemas con sideloading.
        UIApplication.shared.open(url)
    }
    
    // MARK: - OAuth Callback
    
    /// Maneja el callback de OAuth2 cuando Google redirige de vuelta a la app.
    ///
    /// - Parameter url: URL con el authorization code
    ///   Formato: `com.googleusercontent.apps.CLIENT_ID:/oauthredirect?code=XXX&state=YYY`
    func handleOAuthCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            error = "No se recibió authorization code de Google"
            isLoading = false
            return
        }
        
        guard let verifier = codeVerifier else {
            error = "Error interno: no hay code_verifier disponible"
            isLoading = false
            return
        }
        
        do {
            // 4. Intercambiar code por tokens
            try await exchangeCodeForTokens(code: code, codeVerifier: verifier)
            
            // 5. Obtener email del usuario
            await fetchUserEmail()
            
            isAuthenticated = true
            isLoading = false
            codeVerifier = nil
        } catch {
            self.error = "Error al obtener tokens: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Token Exchange
    
    /// Intercambia el authorization code por access_token y refresh_token.
    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws {
        let body: [String: String] = [
            "client_id": OAuthConfig.clientID,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": OAuthConfig.redirectURI
        ]
        
        var request = URLRequest(url: URL(string: OAuthConfig.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            throw OAuthError.tokenExchangeFailed(statusCode: httpResponse.statusCode, body: errorBody)
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Guardar tokens
        try await TokenStorage.shared.saveTokens(from: tokenResponse)
    }
    
    // MARK: - User Info
    
    /// Obtiene el email del usuario autenticado.
    private func fetchUserEmail() async {
        do {
            let token = try await TokenStorage.shared.getValidAccessToken()
            
            var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let email = json["email"] as? String {
                self.userEmail = email
            }
        } catch {
            // No es crítico si falla
            print("Error obteniendo email: \(error)")
        }
    }
    
    // MARK: - Logout
    
    /// Cierra sesión y revoca tokens.
    func logout() async {
        do {
            // Revocar token en Google
            if let tokens = try TokenStorage.shared.loadTokens() {
                var request = URLRequest(url: URL(string: "\(OAuthConfig.revocationEndpoint)?token=\(tokens.accessToken)")!)
                request.httpMethod = "POST"
                _ = try? await URLSession.shared.data(for: request)
            }
        } catch {}
        
        // Limpiar almacenamiento local
        TokenStorage.shared.deleteTokens()
        
        isAuthenticated = false
        userEmail = nil
    }
    
    // MARK: - PKCE Helpers
    
    /// Genera un code_verifier aleatorio (43-128 caracteres, URL-safe).
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Genera el code_challenge a partir del code_verifier (SHA256 + Base64URL).
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Errors

enum OAuthError: LocalizedError {
    case invalidResponse
    case tokenExchangeFailed(statusCode: Int, body: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respuesta inválida del servidor de Google."
        case .tokenExchangeFailed(let code, let body):
            return "Error al intercambiar code por tokens (HTTP \(code)): \(body)"
        }
    }
}
