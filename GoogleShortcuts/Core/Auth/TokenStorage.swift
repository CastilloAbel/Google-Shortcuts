import Foundation
import Security

/// Almacenamiento seguro de tokens OAuth2 usando iOS Keychain.
///
/// Los tokens se almacenan en Keychain (persisten entre reinstalaciones)
/// y en UserDefaults del App Group (accesible desde App Intents).
///
/// ## Comportamiento con Sideloading (7 días):
/// - Keychain: Los datos **persisten** al re-firmar con SideStore.
///   El Keychain está vinculado al bundle ID, no a la firma.
/// - UserDefaults App Group: También persisten si el App Group ID no cambia.
/// - Resultado: NO necesitas re-autenticarte cada 7 días. ✅
actor TokenStorage {
    
    static let shared = TokenStorage()
    
    private init() {}
    
    // MARK: - Token Data
    
    struct TokenData: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int // segundos
        let tokenType: String
        let scope: String?
        let savedAt: Date
        
        /// Fecha de expiración calculada.
        var expirationDate: Date {
            savedAt.addingTimeInterval(TimeInterval(expiresIn))
        }
        
        /// ¿El access token ha expirado?
        var isExpired: Bool {
            Date() >= expirationDate.addingTimeInterval(-60) // 60s de margen
        }
    }
    
    // MARK: - Save
    
    /// Guarda tokens recibidos del token endpoint de Google.
    func saveTokens(from response: TokenResponse) throws {
        let tokenData = TokenData(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            tokenType: response.tokenType,
            scope: response.scope,
            savedAt: Date()
        )
        
        // Serializar a JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tokenData)
        
        // Guardar en Keychain
        try saveToKeychain(data: data, key: OAuthConfig.keychainService)
        
        // Guardar en App Group UserDefaults (para App Intents)
        if let defaults = UserDefaults(suiteName: OAuthConfig.appGroupID) {
            defaults.set(data, forKey: "token_data")
        }
    }
    
    /// Actualiza solo el access token (después de un refresh).
    func updateAccessToken(_ newAccessToken: String, expiresIn: Int) throws {
        guard var existing = try loadTokens() else {
            throw TokenError.noTokensFound
        }
        
        let updated = TokenData(
            accessToken: newAccessToken,
            refreshToken: existing.refreshToken,
            expiresIn: expiresIn,
            tokenType: existing.tokenType,
            scope: existing.scope,
            savedAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(updated)
        
        try saveToKeychain(data: data, key: OAuthConfig.keychainService)
        
        if let defaults = UserDefaults(suiteName: OAuthConfig.appGroupID) {
            defaults.set(data, forKey: "token_data")
        }
    }
    
    // MARK: - Load
    
    /// Carga los tokens almacenados.
    func loadTokens() throws -> TokenData? {
        guard let data = loadFromKeychain(key: OAuthConfig.keychainService) else {
            // Fallback: intentar desde App Group
            if let defaults = UserDefaults(suiteName: OAuthConfig.appGroupID),
               let data = defaults.data(forKey: "token_data") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(TokenData.self, from: data)
            }
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TokenData.self, from: data)
    }
    
    /// Obtiene un access token válido (refresca si está expirado).
    func getValidAccessToken() async throws -> String {
        guard let tokens = try loadTokens() else {
            throw TokenError.noTokensFound
        }
        
        if !tokens.isExpired {
            return tokens.accessToken
        }
        
        // Token expirado → refresh
        guard let refreshToken = tokens.refreshToken else {
            throw TokenError.noRefreshToken
        }
        
        return try await refreshAccessToken(using: refreshToken)
    }
    
    // MARK: - Refresh
    
    /// Refresca el access token usando el refresh token.
    private func refreshAccessToken(using refreshToken: String) async throws -> String {
        var components = URLComponents(string: OAuthConfig.tokenEndpoint)!
        
        let body: [String: String] = [
            "client_id": OAuthConfig.clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        var request = URLRequest(url: URL(string: OAuthConfig.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TokenError.refreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        
        try updateAccessToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)
        
        return tokenResponse.accessToken
    }
    
    // MARK: - Delete
    
    /// Elimina todos los tokens (logout).
    func deleteTokens() {
        deleteFromKeychain(key: OAuthConfig.keychainService)
        
        if let defaults = UserDefaults(suiteName: OAuthConfig.appGroupID) {
            defaults.removeObject(forKey: "token_data")
        }
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(data: Data, key: String) throws {
        // Eliminar existente primero
        deleteFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: "oauth_tokens",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw TokenError.keychainSaveFailed(status)
        }
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: "oauth_tokens",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecAttrAccount as String: "oauth_tokens"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Token Response Models

/// Respuesta del token endpoint de Google (autorización inicial).
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

/// Respuesta del token endpoint de Google (refresh).
/// No incluye refresh_token (Google solo lo envía la primera vez).
struct RefreshTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

// MARK: - Errors

enum TokenError: LocalizedError {
    case noTokensFound
    case noRefreshToken
    case refreshFailed
    case keychainSaveFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .noTokensFound:
            return "No hay tokens guardados. Inicia sesión con Google."
        case .noRefreshToken:
            return "No hay refresh token. Re-autentícate con Google."
        case .refreshFailed:
            return "Error al refrescar el token. Re-autentícate."
        case .keychainSaveFailed(let status):
            return "Error al guardar en Keychain (código: \(status))."
        }
    }
}
