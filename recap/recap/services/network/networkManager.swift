//
//  networkManager.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Combine
import Foundation

final class NetworkManager {

    static let shared = NetworkManager()

    private init() {}

    func request<T: Decodable>(
        endpoint: Endpoint, responseType: T.Type = T.self,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) async throws -> T {

        var urlComponents = URLComponents(string: endpoint.baseURL + endpoint.path)
        urlComponents?.queryItems = endpoint.queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers

        if let body = endpoint.body {
            if let dataBody = body as? Data {
                request.httpBody = dataBody
            } else {
                do {
                    request.httpBody = try JSONEncoder().encode(AnyEncodable(value: body))
                } catch {
                    throw NetworkError.encodingError(error)
                }
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        print("Response JSON: \(String(data: data, encoding: .utf8) ?? "No Data")")

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategy
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
