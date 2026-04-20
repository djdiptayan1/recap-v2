//
//  StreakStatsTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct StreakStatsTool: Tool {
    let name = "getStreakStats"
    let description = "Fetches streak statistics for the patient"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Include active day statistics")
        var includeActiveDays: Bool?
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let response: StreakStatsResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.streakStats(documentID: patientId)
        )

        let base = "Current streak: \(response.data.currentStreak), max streak: \(response.data.maxStreak)."
        let includeActiveDays = arguments.includeActiveDays ?? false
        if includeActiveDays {
            return base + " Active days: \(response.data.activeDays)."
        }
        return base
    }
}
#endif
