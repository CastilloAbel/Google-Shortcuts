import Foundation
import Security

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?
    let tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
    }
}

class TokenStorage {
    static let shared = TokenStorage()
    
    private let service = "com.abel.googleshortcuts.tokens"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let expirationKey = "token_expiration"
    
    struct TokenData {
        let accessToken: String
        let refreshToken: String
        let expirationDate: Date
        
        var isExpired: Bool {
            return Date() >= expirationDate
        }
    }
    
    func getValidAccessToken() async throws -> String {
        guard let tokens = try loadTokens() else {
            throw TokenError.noRefreshToken
        }
        if tokens.isExpired {
            let refreshed = try await refreshAccessToken()
            return refreshed.accessToken
        }
        return tokens.accessToken
    }
    
    // MARK: - Save Tokens
    
    func saveTokens(from response: TokenResponse) {
        saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? "",
            expiresIn: response.expiresIn
        )
    }
    
    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        let expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)
        
        UserDefaults.standard.set(expiration.timeIntervalSince1970, forKey: expirationKey)
    }
    
    // MARK: - Load Tokens
    
    func loadTokens() throws -> TokenData? {
        guard let accessToken = loadFromKeychain(key: accessTokenKey),
              let refreshToken = loadFromKeychain(key: refreshTokenKey) else {
            return nil
        }
        
        let expiration = UserDefaults.standard.double(forKey: expirationKey)
        let expirationDate = Date(timeIntervalSince1970: expiration)
        
        return TokenData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expirationDate: expirationDate
        )
    }
    
    // MARK: - Refresh Token
    
    func refreshAccessToken() async throws -> TokenData {
        guard let existing = try loadTokens() else {
            throw TokenError.noRefreshToken
        }
        
        let url = URL(string: OAuthConfig.tokenEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = [
            "client_id=\(OAuthConfig.clientID)",
            "refresh_token=\(existing.refreshToken)",
            "grant_type=refresh_token"
        ].joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TokenError.refreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        saveTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: existing.refreshToken,
            expiresIn: tokenResponse.expiresIn
        )
        
        return try loadTokens()!
    }
    
    // MARK: - Delete Tokens
    
    func deleteTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expirationKey)
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
        
        var addQuery = query
        addQuery[kSecValueData as String] = data
        
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Errors
    
    enum TokenError: Error, LocalizedError {
        case noRefreshToken
        case refreshFailed
        
        var errorDescription: String? {
            switch self {
            case .noRefreshToken: return "No hay refresh token disponible"
            case .refreshFailed: return "Error al renovar el token"
            }
        }
    }
}
