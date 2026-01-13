//
//  MemoryQuizHistoryListView.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import SwiftUI
struct MemoryQuizHistoryListView: View {
    let reports: [MemoryReport]

    var body: some View {
        List {
            ForEach(reports, id: \.id) { report in
                NavigationLink(destination: MemoryQuizDetailView(report: report)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.safeStatus)
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text(report.formattedDate)
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    .padding(.vertical, 4) // Breathing room inside the row
                }
                // Make the row background clear so the list background shows
                .listRowBackground(Color.white.opacity(0.6))
            }
        }
        .listStyle(.insetGrouped) // Looks better than 'automatic' for this style
        .scrollContentBackground(.hidden) // CRITICAL: This removes the default gray/white system background
        .standardBackground()
        .navigationTitle("Memory Quiz History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
