import Foundation

/// API client for Hogwarts backend
/// Mirrors: Server actions pattern from actions.ts files
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let keychain = KeychainService()

    private init() {
        self.baseURL = URL(string: "https://ed.databayt.org/api")!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - HTTP Methods

    /// GET request
    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        try await request(path, method: .get)
    }

    /// GET with query parameters
    func get<T: Decodable>(
        _ path: String,
        query: [String: String],
        as type: T.Type = T.self
    ) async throws -> T {
        try await request(path, method: .get, query: query)
    }

    /// POST request
    func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B,
        as type: T.Type = T.self
    ) async throws -> T {
        try await request(path, method: .post, body: body)
    }

    /// PUT request
    func put<T: Decodable, B: Encodable>(
        _ path: String,
        body: B,
        as type: T.Type = T.self
    ) async throws -> T {
        try await request(path, method: .put, body: body)
    }

    /// DELETE request
    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(path, method: .delete)
    }

    // MARK: - Core Request

    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        query: [String: String]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(path)

        // Add query parameters
        if let query = query, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url ?? url
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header
        if let token = keychain.get(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)

        case 401:
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 422:
            let error = try? JSONDecoder().decode(ValidationError.self, from: data)
            throw APIError.validationFailed(error?.message ?? "Validation failed")

        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)

        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }

    // MARK: - Device Token Registration

    func registerDeviceToken(_ token: String) async throws {
        struct TokenRequest: Encodable {
            let deviceToken: String
            let platform: String = "ios"
        }

        let _: EmptyResponse = try await post(
            "/notifications/register",
            body: TokenRequest(deviceToken: token)
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct EmptyResponse: Decodable {}

struct ValidationError: Decodable {
    let message: String
    let errors: [String: [String]]?
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationFailed(String)
    case serverError(Int)
    case unknown(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please sign in to continue"
        case .forbidden:
            return "You don't have permission"
        case .notFound:
            return "Resource not found"
        case .validationFailed(let message):
            return message
        case .serverError(let code):
            return "Server error (\(code))"
        case .unknown(let code):
            return "Unknown error (\(code))"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
