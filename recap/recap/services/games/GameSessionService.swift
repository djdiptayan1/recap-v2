//
//  GameSessionService.swift
//  recap
//

import Foundation

private enum GamesAPI: Endpoint {
    case submitSession(request: GameSessionRequest)
    case analytics(patientId: String)
    case history(patientId: String)

    var path: String {
        switch self {
        case .submitSession:
            return "\(AppConfig.ApiEndpoints.games)/session"
        case .analytics(let patientId):
            return "\(AppConfig.ApiEndpoints.games)/analytics/\(patientId)"
        case .history(let patientId):
            return "\(AppConfig.ApiEndpoints.games)/history/\(patientId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .submitSession:
            return .post
        case .analytics, .history:
            return .get
        }
    }

    var body: Encodable? {
        switch self {
        case .submitSession(let request):
            return request
        case .analytics, .history:
            return nil
        }
    }
}

final class GameSessionService {
    static let shared = GameSessionService()

    private init() {}

    func submitSession(_ request: GameSessionRequest) async throws {
        let _: GameSessionResponse = try await NetworkManager.shared.request(
            endpoint: GamesAPI.submitSession(request: request)
        )
    }

    func fetchAnalytics(patientId: String) async throws -> GameAnalyticsData {
        let response: GameAnalyticsResponse = try await NetworkManager.shared.request(
            endpoint: GamesAPI.analytics(patientId: patientId)
        )
        return response.data
    }

    func fetchHistory(patientId: String) async throws -> [RecentGameSession] {
        struct HistoryResponse: Codable {
            let success: Bool
            let data: [RecentGameSession]
        }

        let response: HistoryResponse = try await NetworkManager.shared.request(
            endpoint: GamesAPI.history(patientId: patientId)
        )
        return response.data
    }

    func currentPatientDocumentID() -> String? {
        KeychainManager.shared.getString(key: .patientDocumentID)
            ?? KeychainManager.shared.getString(key: .documentID)
    }
}

struct GameSessionSubmissionBuilder {
    let gameType: RecapGameType
    let score: Int
    let durationSeconds: Int
    let startedAt: Date
    let completedAt: Date
    let outcome: GameSessionOutcome
    let completed: Bool
    let levelReached: Int?
    let accuracy: Double?
    let mistakes: Int
    let difficulty: String?
    let metadata: [String: String]

    func makeRequest(documentId: String) -> GameSessionRequest {
        GameSessionRequest(
            documentId: documentId,
            gameType: gameType.rawValue,
            score: score,
            durationSeconds: durationSeconds,
            startedAt: startedAt.ISO8601Format(),
            completedAt: completedAt.ISO8601Format(),
            outcome: outcome.rawValue,
            completed: completed,
            levelReached: levelReached,
            accuracy: accuracy,
            mistakes: mistakes,
            difficulty: difficulty,
            metadata: metadata
        )
    }
}
