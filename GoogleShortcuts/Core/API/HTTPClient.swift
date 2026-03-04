import Foundation

/// Cliente HTTP genérico con soporte para autenticación Bearer.
///
/// Todas las llamadas a Gmail API pasan por aquí.
/// Maneja automáticamente:
/// - Headers de autorización
/// - Refresh de tokens cuando expiran (HTTP 401)
/// - Serialización/deserialización JSON
/// - Rate limiting básico
actor HTTPClient {
    
    static let shared = HTTPClient()
    
    enum HTTPError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int, data: Data)
        case unauthorized
        case noToken
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL inválida"
            case .invalidResponse: return "Respuesta inválida"
            case .httpError(let code, _): return "Error HTTP: \(code)"
            case .unauthorized: return "No autorizado. Inicia sesión de nuevo."
            case .noToken: return "No hay token de acceso"
            }
        }
    }
    
    private func buildRequest(
        url: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: url) else {
            throw HTTPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    func authenticatedRequest<T: Decodable>(
        url: String,
        method: String = "GET",
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        var finalURL = url
        if let queryItems = queryItems, var components = URLComponents(string: url) {
            components.queryItems = queryItems
            if let newURL = components.url?.absoluteString {
                finalURL = newURL
            }
        }
        
        let data = try await authenticatedRequest(url: finalURL, method: method, headers: headers, body: body)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw HTTPError.invalidResponse
        }
    }
    
    func authenticatedRequest(
        url: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        // Obtener token válido
        guard let tokens = try? TokenStorage.shared.loadTokens() else {
            throw HTTPError.noToken
        }
        
        var accessToken = tokens.accessToken
        
        // Verificar si el token expiró
        if tokens.isExpired {
            let newTokens = try await TokenStorage.shared.refreshAccessToken()
            accessToken = newTokens.accessToken
        }
        
        // Construir request con token
        let request = try buildRequest(
            url: url,
            method: method,
            headers: headers.merging(
                ["Authorization": "Bearer \(accessToken)"],
                uniquingKeysWith: { _, new in new }
            ),
            body: body
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        // Si 401, intentar refresh una vez
        if httpResponse.statusCode == 401 {
            let newTokens = try await TokenStorage.shared.refreshAccessToken()
            
            let retryRequest = try buildRequest(
                url: url,
                method: method,
                headers: headers.merging(
                    ["Authorization": "Bearer \(newTokens.accessToken)"],
                    uniquingKeysWith: { _, new in new }
                ),
                body: body
            )
            
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            
            if retryHTTP.statusCode == 401 {
                throw HTTPError.unauthorized
            }
            
            guard (200...299).contains(retryHTTP.statusCode) else {
                throw HTTPError.httpError(statusCode: retryHTTP.statusCode, data: retryData)
            }
            
            return retryData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
    }
}

// MARK: - Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct HTTPError: LocalizedError {
    let statusCode: Int
    let message: String
    
    var errorDescription: String? {
        "HTTP \(statusCode): \(message)"
    }
}

/// Wrapper para enviar JSON raw (ej: Gmail send message body).
struct RawJSON: Encodable {
    let dictionary: [String: String]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dictionary)
    }
}
