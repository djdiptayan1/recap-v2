//
//  home_family.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//
import SwiftUI

struct home_family: View {
    @StateObject private var reminderViewModel = ReminderViewModel()
    @State private var showProfile = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    QuestionsCard()
                    StreaksCard()
                    MemoryAnalyticsCard()
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.trigger(.selection)
                        showProfile.toggle()
                    }) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: remindersView(viewModel: reminderViewModel)) {
                        Image(systemName: "bell.badge.waveform.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.alert)
                    }
                }

            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileFamilyView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    home_family()
}
