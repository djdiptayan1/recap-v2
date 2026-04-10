//
//  OnboardingStateStore.swift
//  recap
//

import Foundation

struct OnboardingProfile: Codable {
    let role: String
    let goals: [String]
    let supportStyle: String
    let wantsNotifications: Bool
    let aiModeSummary: String
    let completedAt: Date
}

final class OnboardingStateStore {
    static let shared = OnboardingStateStore()

    private let defaults = UserDefaults.standard

    private init() {}

    func hasCompletedOnboarding(for user: patientModel) -> Bool {
        defaults.bool(forKey: completionKey(for: user))
    }

    func completeOnboarding(for user: patientModel, profile: OnboardingProfile) {
        defaults.set(true, forKey: completionKey(for: user))
        if let encoded = try? JSONEncoder().encode(profile) {
            defaults.set(encoded, forKey: profileKey(for: user))
        }
    }

    func profile(for user: patientModel) -> OnboardingProfile? {
        guard let data = defaults.data(forKey: profileKey(for: user)) else {
            return nil
        }
        return try? JSONDecoder().decode(OnboardingProfile.self, from: data)
    }

    private func completionKey(for user: patientModel) -> String {
        "recap.onboarding.completed.\(user.type ?? "unknown")"
    }

    private func profileKey(for user: patientModel) -> String {
        "recap.onboarding.profile.\(user.id ?? "anonymous")"
    }
}
