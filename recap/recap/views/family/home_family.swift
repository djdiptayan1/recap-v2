//
//  home_family.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//
import SwiftUI

struct home_family: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var reminderViewModel = ReminderViewModel()
    @State private var showProfile = false

    private var patientId: String {
        KeychainManager.shared.getString(key: .patientDocumentID) ?? ""
    }

    private var patientName: String {
        let linked = appState.currentUser?.linkedPatient
        let full = "\(linked?.firstName ?? "") \(linked?.lastName ?? "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return full.isEmpty ? "patient" : full
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    QuestionsCard()
                    StreaksCard()
                    if !patientId.isEmpty {
                        MoodInsightsCard(patientId: patientId, patientName: patientName)
                    }
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
                    .accessibilityLabel("Open profile")
                    .accessibilityHint("Shows profile and account settings")
                    .accessibilityInputLabels(["profile", "account", "settings"])
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: remindersView(viewModel: reminderViewModel)) {
                        Image(systemName: "bell.badge.waveform.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.alert)
                    }
                    .accessibilityLabel("Open reminders")
                    .accessibilityHint("Shows the patient reminders list")
                    .accessibilityInputLabels(["reminders", "alarm", "notifications"])
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
