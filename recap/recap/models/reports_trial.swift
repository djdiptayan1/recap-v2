//
//  reports_trial.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import Foundation
import SwiftUI
import Combine

enum TimeFrame: String, CaseIterable, Identifiable {
    case immediate = "Today"
    case recent = "Weekly"
    case remote = "Monthly"
    var id: String { self.rawValue }
}

struct AnalyticsData: Identifiable, Equatable {
    let id = UUID()
    let label: String    // e.g., "9 AM", "Mon", "Jan"
    let value: Double    // The score
    let secondaryValue: Double? // For "Wrong" answers in immediate view
    let date: Date
}

// MARK: - API Response Models

struct AnalyticsDashboardResponse: Codable {
    let success: Bool
    let data: AnalyticsDashboardData
}

struct AnalyticsDashboardData: Codable {
    let daily: DailyAnalytics
    let weekly: [WeeklyAnalytics]
    let monthly: [MonthlyAnalytics]
    let declineAlert: DeclineAlert
}

struct DailyAnalytics: Codable {
    let correct: Int
    let incorrect: Int
    let unanswered: Int
    let total: Int
    let score: Double
}

struct WeeklyAnalytics: Codable {
    let date: String
    let label: String
    let score: Double
    let correct: Int
    let incorrect: Int
    let total: Int
}

struct MonthlyAnalytics: Codable {
    let month: String
    let label: String
    let score: Double
    let correct: Int
    let total: Int
}

struct DeclineAlert: Codable {
    let detected: Bool
    let message: String
    let weeklyScores: [Double]
}

// MARK: - API Endpoint

private enum AnalyticsAPI: Endpoint {
    case dashboard(patientId: String)

    var path: String {
        switch self {
        case .dashboard(let patientId):
            return "\(AppConfig.ApiEndpoints.analyticsDashboard)/\(patientId)"
        }
    }

    var method: HTTPMethod { .get }
}

// MARK: - ViewModel

class AnalyticsViewModel: ObservableObject {
    @Published var selectedTimeFrame: TimeFrame = .immediate
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var dailyData: [AnalyticsData] = []
    @Published var weeklyData: [AnalyticsData] = []
    @Published var monthlyData: [AnalyticsData] = []
    @Published var declineAlert: DeclineAlert?

    private let patientId: String

    init(patientId: String = "") {
        self.patientId = patientId
        if !patientId.isEmpty {
            fetchAnalytics()
        }
    }

    func fetchAnalytics() {
        guard !patientId.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let response: AnalyticsDashboardResponse = try await NetworkManager.shared.request(
                    endpoint: AnalyticsAPI.dashboard(patientId: patientId),
                    keyDecodingStrategy: .useDefaultKeys
                )

                if response.success {
                    let data = response.data

                    // Daily data
                    self.dailyData = [
                        AnalyticsData(label: "Correct", value: Double(data.daily.correct), secondaryValue: nil, date: Date()),
                        AnalyticsData(label: "Incorrect", value: Double(data.daily.incorrect), secondaryValue: nil, date: Date())
                    ]

                    // Weekly data
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"

                    self.weeklyData = data.weekly.map { item in
                        let date = dateFormatter.date(from: item.date) ?? Date()
                        return AnalyticsData(label: item.label, value: item.score, secondaryValue: nil, date: date)
                    }

                    // Monthly data
                    self.monthlyData = data.monthly.map { item in
                        let date = dateFormatter.date(from: "\(item.month)-01") ?? Date()
                        return AnalyticsData(label: item.label, value: item.score, secondaryValue: nil, date: date)
                    }

                    // Decline alert
                    self.declineAlert = data.declineAlert
                } else {
                    self.errorMessage = "Failed to fetch analytics"
                }
            } catch {
                self.errorMessage = error.localizedDescription
                print("Error fetching analytics: \(error)")
            }

            self.isLoading = false
        }
    }
}
