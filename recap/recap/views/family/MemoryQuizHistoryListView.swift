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
                }
                // .listRowBackground(Color.clear)
                // .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Memory Quiz History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
