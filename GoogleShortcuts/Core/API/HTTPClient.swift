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
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Authenticated Requests
    
    /// Ejecuta una request autenticada con Bearer token.
    /// Si el token ha expirado, lo refresca automáticamente y reintenta.
    func authenticatedRequest<T: Decodable>(
        url: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        responseType: T.Type
    ) async throws -> T {
        let token = try await TokenStorage.shared.getValidAccessToken()
        
        do {
            return try await executeRequest(
                url: url,
                method: method,
                body: body,
                queryItems: queryItems,
                token: token,
                responseType: responseType
            )
        } catch let error as HTTPError where error.statusCode == 401 {
            // Token inválido → intentar refresh y reintentar una vez
            let newToken = try await TokenStorage.shared.getValidAccessToken()
            return try await executeRequest(
                url: url,
                method: method,
                body: body,
                queryItems: queryItems,
                token: newToken,
                responseType: responseType
            )
        }
    }
    
    /// Ejecuta una request autenticada sin esperar body de respuesta.
    func authenticatedRequestNoResponse(
        url: String,
        method: HTTPMethod = .post,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        let token = try await TokenStorage.shared.getValidAccessToken()
        
        var request = try buildRequest(
            url: url,
            method: method,
            body: body,
            queryItems: queryItems,
            token: token
        )
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw HTTPError(statusCode: statusCode, message: "Request failed")
        }
    }
    
    // MARK: - Private
    
    private func executeRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?,
        token: String,
        responseType: T.Type
    ) async throws -> T {
        let request = try buildRequest(
            url: url,
            method: method,
            body: body,
            queryItems: queryItems,
            token: token
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError(statusCode: 0, message: "Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Intentar parsear error de Gmail API
            if let apiError = try? decoder.decode(GmailAPIError.self, from: data) {
                throw HTTPError(
                    statusCode: httpResponse.statusCode,
                    message: apiError.error.message
                )
            }
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HTTPError(statusCode: httpResponse.statusCode, message: body)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    private func buildRequest(
        url: String,
        method: HTTPMethod,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?,
        token: String
    ) throws -> URLRequest {
        var components = URLComponents(string: url)!
        
        if let queryItems = queryItems {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        
        guard let finalURL = components.url else {
            throw HTTPError(statusCode: 0, message: "Invalid URL: \(url)")
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        
        return request
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
