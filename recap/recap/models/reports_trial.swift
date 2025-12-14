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
    case remote = "Quarterly"
    var id: String { self.rawValue }
}

struct AnalyticsData: Identifiable, Equatable {
    let id = UUID()
    let label: String    // e.g., "9 AM", "Mon", "Q1"
    let value: Double    // The score
    let secondaryValue: Double? // For "Wrong" answers in immediate view
    let date: Date
}

// Mock Data Generator
class AnalyticsViewModel: ObservableObject {
    @Published var selectedTimeFrame: TimeFrame = .immediate
    
    let dailyData: [AnalyticsData] = [
        AnalyticsData(label: "Correct", value: 5, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Incorrect", value: 2, secondaryValue: nil, date: Date())
    ]
    
    let weeklyData: [AnalyticsData] = [
        AnalyticsData(label: "Mon", value: 60, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Tue", value: 75, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Wed", value: 65, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Thu", value: 85, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Fri", value: 70, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Sat", value: 90, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Sun", value: 80, secondaryValue: nil, date: Date())
    ]
    
    let quarterlyData: [AnalyticsData] = [
        AnalyticsData(label: "Q1", value: 65, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Q2", value: 72, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Q3", value: 68, secondaryValue: nil, date: Date()),
        AnalyticsData(label: "Q4", value: 80, secondaryValue: nil, date: Date())
    ]
}
