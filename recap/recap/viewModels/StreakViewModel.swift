//
//  StreakViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation
import Combine

class StreakViewModel: ObservableObject {
    @Published var maxStreak: Int = 0
    @Published var currentStreak: Int = 0
    @Published var activeDays: Int = 0
    @Published var streakDates: [String: Bool] = [:]
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var documentID: String
    private var hasFetchedStats = false
    
    init(documentID: String) {
        self.documentID = documentID
    }
    
    func updateDocumentID(_ id: String) {
        self.documentID = id
    }
    
    // MARK: - API Endpoints
    private enum StreakAPI: Endpoint {
        case stats(documentID: String)
        case year(documentID: String, year: Int)
        case month(documentID: String, yearMonth: String)
        
        var path: String {
            switch self {
            case .stats(let documentID):
                return AppConfig.ApiEndpoints.streakStats + "/\(documentID)"
//                return "streaks/stats/\(documentID)"
            case .year(let documentID, _):
                return AppConfig.ApiEndpoints.streakYear + "/\(documentID)"
            case .month(let documentID, _):
                return AppConfig.ApiEndpoints.streakMonth + "/\(documentID)"
            }
        }
        
        var method: HTTPMethod { .get }
        
        var queryItems: [URLQueryItem]? {
            switch self {
            case .stats:
                return nil
            case .year(_, let year):
                return [URLQueryItem(name: "year", value: String(year))]
            case .month(_, let yearMonth):
                return [URLQueryItem(name: "yearMonth", value: yearMonth)]
            }
        }
    }
    
    // MARK: - Fetch Methods
    
    @MainActor
    func fetchStreakStats() async {
        guard !documentID.isEmpty else { return }
        guard !hasFetchedStats else { return }

        // Use prefetched data if available
        if let cached = DataPrefetchManager.shared.streakStats {
            self.maxStreak = cached.maxStreak
            self.currentStreak = cached.currentStreak
            self.activeDays = cached.activeDays
            hasFetchedStats = true
            return
        }

        isLoading = true
        errorMessage = nil
        
        do {
            let response: StreakStatsResponse = try await NetworkManager.shared.request(endpoint: StreakAPI.stats(documentID: documentID))
            if response.success {
                self.maxStreak = response.data.maxStreak
                self.currentStreak = response.data.currentStreak
                self.activeDays = response.data.activeDays
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching streak stats: \(error)")
        }
        
        hasFetchedStats = true
        isLoading = false
    }
    
    @MainActor
    func fetchStreakMonth(year: Int, month: Int) async {
        guard !documentID.isEmpty else { return }
        // No loading state needed for silent updates usually, but can add if needed
        
        let yearMonth = String(format: "%04d-%02d", year, month)
        
        do {
            let response: StreakMonthResponse = try await NetworkManager.shared.request(endpoint: StreakAPI.month(documentID: documentID, yearMonth: yearMonth))
            if response.success {
                self.streakDates = response.data
            }
        } catch {
            print("Error fetching streak month: \(error)")
        }
    }
}
