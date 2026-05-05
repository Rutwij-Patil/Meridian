//
//
//  APIClient.swift
//  Meridian
//

internal import Foundation

// MARK: - Environment

enum APIEnvironment {
    case local
    case production

    var baseURL: String {
        switch self {
        case .local:      return "https://unexclusively-stripier-carlotta.ngrok-free.dev"
        case .production: return "https://api.meridian.app"
        }
    }

    static var current: APIEnvironment {
        #if DEBUG
        return .local
        #else
        return .production
        #endif
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL(String)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case noData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):    return "Invalid URL: \(url)"
        case .httpError(let code, _): return "HTTP \(code)"
        case .decodingError(let e):   return "Decode failed: \(e.localizedDescription)"
        case .noData:                 return "Empty response"
        case .unknown(let e):         return e.localizedDescription
        }
    }
}

// MARK: - Request

struct APIRequest<Response: Decodable> {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: (any Encodable)?
    let decoder: JSONDecoder

    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: (any Encodable)? = nil,
        decoder: JSONDecoder = APIClient.defaultDecoder
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.decoder = decoder
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case patch  = "PATCH"
}

// MARK: - Client

final class APIClient {

    static let shared = APIClient(environment: .current)

    static let defaultDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let environment: APIEnvironment
    private let session: URLSession

    init(environment: APIEnvironment, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func send<R: Decodable>(_ request: APIRequest<R>) async throws -> R {
        let urlRequest = try buildURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode, data: data)
        }

        do {
            return try request.decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func download(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL(urlString)
        }
        let (tempURL, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                data: nil
            )
        }
        return tempURL
    }

    private func buildURLRequest<R>(from request: APIRequest<R>) throws -> URLRequest {
        let rawURL = environment.baseURL + request.path
        guard let url = URL(string: rawURL) else {
            throw APIError.invalidURL(rawURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        return urlRequest
    }
}
