//
//  GameAnalyticsViewModel.swift
//  recap
//

import Foundation
import Combine

@MainActor
final class GameAnalyticsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analytics: GameAnalyticsData?

    private let patientId: String

    init(patientId: String) {
        self.patientId = patientId
    }

    func fetch() async {
        guard !patientId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            analytics = try await GameSessionService.shared.fetchAnalytics(patientId: patientId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
