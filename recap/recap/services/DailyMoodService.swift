import Foundation

final class DailyMoodService {
    static let shared = DailyMoodService()

    private init() {}

    private enum MoodAPI: Endpoint {
        case save(request: DailyMoodRequest)
        case today(patientId: String)
        case history(patientId: String, days: Int)

        var path: String {
            switch self {
            case .save:
                return AppConfig.ApiEndpoints.mood
            case .today(let patientId):
                return "\(AppConfig.ApiEndpoints.mood)/today/\(patientId)"
            case .history(let patientId, _):
                return "\(AppConfig.ApiEndpoints.mood)/history/\(patientId)"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .save:
                return .post
            case .today, .history:
                return .get
            }
        }

        var body: Encodable? {
            switch self {
            case .save(let request):
                return request
            case .today, .history:
                return nil
            }
        }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .history(_, let days):
                return [URLQueryItem(name: "days", value: String(days))]
            case .save, .today:
                return nil
            }
        }
    }

    func saveMood(patientId: String, mood: DailyMoodKey) async throws -> DailyMoodEntry? {
        let response: DailyMoodResponse = try await NetworkManager.shared.request(
            endpoint: MoodAPI.save(
                request: DailyMoodRequest(patientId: patientId, moodKey: mood.rawValue)
            ),
            keyDecodingStrategy: .useDefaultKeys,
            timeoutSeconds: 20
        )
        return response.data
    }

    func fetchTodayMood(patientId: String) async throws -> DailyMoodEntry? {
        let response: DailyMoodResponse = try await NetworkManager.shared.request(
            endpoint: MoodAPI.today(patientId: patientId),
            keyDecodingStrategy: .useDefaultKeys,
            timeoutSeconds: 12
        )
        return response.data
    }

    func fetchMoodHistory(patientId: String, days: Int = 7) async throws -> [DailyMoodEntry] {
        let response: DailyMoodHistoryResponse = try await NetworkManager.shared.request(
            endpoint: MoodAPI.history(patientId: patientId, days: days),
            keyDecodingStrategy: .useDefaultKeys,
            timeoutSeconds: 12
        )
        return response.data
    }
}
