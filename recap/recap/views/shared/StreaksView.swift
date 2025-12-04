//
//  StreaksView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
import Combine

struct StreaksView: View {
    let documentID: String
    @StateObject private var viewModel: StreakViewModel
    @State private var showInfoCard = false
    
    @State private var currentMonth: Int
    @State private var currentYear: Int
    
    init(documentID: String) {
        self.documentID = documentID
        _viewModel = StateObject(wrappedValue: StreakViewModel(documentID: documentID))
        
        let calendar = Calendar.current
        let now = Date()
        _currentMonth = State(initialValue: calendar.component(.month, from: now))
        _currentYear = State(initialValue: calendar.component(.year, from: now))
    }
    
    var body: some View {
        ZStack {
        
            ScrollView {
                VStack(spacing: 24) {
                    
                    UnifiedStatsCard(
                        maxStreak: viewModel.maxStreak,
                        currentStreak: viewModel.currentStreak,
                        activeDays: viewModel.activeDays
                    )
                    .padding(.top, 10)
                    
                    VStack(spacing: 0) {
                        CalendarHeader(
                            month: monthName(currentMonth),
                            year: "\(currentYear)",
                            onPrevious: previousMonth,
                            onNext: nextMonth
                        )
                        
                        Divider()
                            .background(AppConfig.Colors.stroke)
                            .padding(.horizontal, 16)
                        
                        CalendarGrid(
                            currentMonth: currentMonth,
                            currentYear: currentYear,
                            streakDates: viewModel.streakDates
                        )
                        .padding(16)
                    }
//                    .background(Color.white)
                    .glassEffect(.clear, in: .rect)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Text("Highlighted days indicate completed activity.")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .standardBackground()
        .navigationTitle("Streaks")
        .onAppear {
            loadData()
        }
        .onChange(of: currentMonth) { _ in
            fetchMonthData()
        }
    }
    
    private func loadData() {
        Task {
            await viewModel.fetchStreakStats()
            await viewModel.fetchStreakMonth(year: currentYear, month: currentMonth)
        }
    }
    
    private func fetchMonthData() {
        Task {
            await viewModel.fetchStreakMonth(year: currentYear, month: currentMonth)
        }
    }
    
    private func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }
    
    private func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: month)) ?? Date()
        return formatter.string(from: date)
    }
}

struct UnifiedStatsCard: View {
    let maxStreak: Int
    let currentStreak: Int
    let activeDays: Int
    
    var body: some View {
        HStack(spacing: 0) {
            StatColumn(
                value: "\(maxStreak)",
                label: "Max Streak",
                icon: "trophy.fill",
                color: Color.yellow
            )
            
            Rectangle()
                .fill(AppConfig.Colors.stroke)
                .frame(width: 1, height: 40)
            
            StatColumn(
                value: "\(currentStreak)",
                label: "Current",
                icon: "flame.fill",
                color: Color.orange
            )
            
            Rectangle()
                .fill(AppConfig.Colors.stroke)
                .frame(width: 1, height: 40)
            
            StatColumn(
                value: "\(activeDays)",
                label: "Active Days",
                icon: "calendar.badge.clock",
                color: AppConfig.Colors.accent
            )
        }
        .padding(.vertical, 24)
//        .background(Color.white)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.system(size: 18))
//                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                
                Text(label)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 2. Clean Calendar Components

struct CalendarHeader: View {
    let month: String
    let year: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Text("\(month) \(year)")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConfig.Colors.textSecondary)
                }
                
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
        }
        .padding(20)
    }
}

struct CalendarGrid: View {
    let currentMonth: Int
    let currentYear: Int
    let streakDates: [String: Bool]
    
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(getDaysInMonth(), id: \.self) { day in
                    CalendarDayCell(
                        day: day,
                        hasStreak: streakDates["\(currentYear)-\(String(format: "%02d", currentMonth))-\(String(format: "%02d", day))"] == true,
                        isToday: isToday(day: day)
                    )
                }
            }
        }
    }
    
    private func getDaysInMonth() -> [Int] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: currentYear, month: currentMonth)
        guard let date = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        
        let firstDayComponents = DateComponents(year: currentYear, month: currentMonth, day: 1)
        guard let firstDay = calendar.date(from: firstDayComponents) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        
        var days = Array(repeating: 0, count: weekday)
        days.append(contentsOf: Array(range))
        return days
    }
    
    private func isToday(day: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        return todayComponents.year == currentYear && todayComponents.month == currentMonth && todayComponents.day == day
    }
}

struct CalendarDayCell: View {
    let day: Int
    let hasStreak: Bool
    let isToday: Bool
    
    var body: some View {
        if day == 0 {
            Color.clear.frame(height: 36)
        } else {
            ZStack {
                if hasStreak {
                    Circle()
                        .fill(AppConfig.Colors.accent)
                } else if isToday {
                    Circle()
                        .stroke(AppConfig.Colors.accent, lineWidth: 1.5)
                }
                
                Text("\(day)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(hasStreak ? .white : (isToday ? AppConfig.Colors.accent : AppConfig.Colors.textPrimary))
            }
            .frame(width: 36, height: 36)
        }
    }
}

#Preview {
    NavigationStack {
        StreaksView(documentID: "dummyy")
    }
}
