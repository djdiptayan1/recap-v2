//
//  profile.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SDWebImageSwiftUI
import SwiftUI

struct ProfileView: View {
    @State private var showMemoryCheck = false
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var quizViewModel = MemoryQuizViewModel()

    @State private var showLogoutAlert = false
    @State private var showCopyAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false

    private var lastCheckSubtitle: String {
        guard let latest = quizViewModel.reports.first else {
            return "No check taken yet"
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: latest.date) else {
            return "Last check: \(latest.date)"
        }
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month], from: date, to: Date())
        if let months = components.month, months > 0 {
            return "Last check: \(months) month\(months == 1 ? "" : "s") ago"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "Last check: \(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else if let days = components.day, days > 0 {
            return "Last check: \(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "Last check: \(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "Last check: \(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Last check: just now"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let patient = appState.currentUser {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 110, height: 110)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                                if let profileImageURL = patient.profileImageURL,
                                    let url = URL(string: profileImageURL)
                                {
                                    WebImage(url: url)
                                        .resizable()
                                        .indicator(.activity)
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .foregroundColor(Color.gray.opacity(0.3))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .foregroundColor(Color.gray.opacity(0.3))
                                }
                            }

                            VStack(spacing: 4) {
                                Text("\(patient.firstName) \(patient.lastName)")
                                    .font(AppConfig.Fonts.titleMedium)
                                    .foregroundColor(AppConfig.Colors.textPrimary)

                                Text(patient.email)
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 20)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PATIENT ID")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.7))
                                    .tracking(1)

                                Text(patient.patientUID)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppConfig.Colors.accent)
                            }

                            Spacer()

                            Button(action: {
                                HapticManager.shared.trigger(.selection)
                                UIPasteboard.general.string = patient.patientUID
                                showCopyAlert = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(AppConfig.Colors.accent)
                                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                            }
                        }
                        .padding(20)
                        //                    .background(Color.white)
                        .glassEffect(.clear, in: .rect)
                        .cornerRadius(AppConfig.UI.cornerRadius)
                        .shadow(
                            color: AppConfig.Colors.accent.opacity(0.15), radius: 15, x: 0, y: 8
                        )
                        .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Medical Details")

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16
                            ) {
                                InfoTile(
                                    icon: "calendar", title: "Birth Date",
                                    value: patient.dateOfBirth)
                                InfoTile(
                                    icon: "drop.fill", title: "Blood Type",
                                    value: patient.bloodGroup, iconColor: .red)
                                InfoTile(
                                    icon: "person.text.rectangle", title: "Sex", value: patient.sex)
                                InfoTile(
                                    icon: "chart.bar.fill", title: "Stage", value: patient.stage,
                                    iconColor: .orange)
                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Health & Settings")

                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "brain.head.profile", title: "Memory Check",
                                    subtitle: lastCheckSubtitle
                                ) {
                                    HapticManager.shared.trigger(.selection)
                                    showMemoryCheck = true
                                }

                                Divider().padding(.leading, 50)

                                // Citations Link
                                NavigationLink(destination: CitationsView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "text.book.closed")
                                            .font(.system(size: 18))
                                            .frame(width: 24)
                                            .foregroundColor(AppConfig.Colors.textSecondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Medical Citations")
                                                .font(AppConfig.Fonts.body)
                                                .foregroundColor(AppConfig.Colors.textPrimary)

                                            Text("View sources")
                                                .font(AppConfig.Fonts.small)
                                                .foregroundColor(AppConfig.Colors.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppConfig.Colors.stroke)
                                    }
                                    .padding(AppConfig.UI.screenPadding - 10)
                                }

                                Divider().padding(.leading, 50)

                                // Privacy Policy Link
                                NavigationLink(destination: privaryPolicy()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "hand.raised.fill")
                                            .font(.system(size: 18))
                                            .frame(width: 24)
                                            .foregroundColor(AppConfig.Colors.textSecondary)

                                        Text("Privacy Policy")
                                            .font(AppConfig.Fonts.body)
                                            .foregroundColor(AppConfig.Colors.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppConfig.Colors.stroke)
                                    }
                                    .padding(AppConfig.UI.screenPadding - 10)
                                }

                                Divider().padding(.leading, 50)

                                // Support Link
                                NavigationLink(destination: support()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.system(size: 18))
                                            .frame(width: 24)
                                            .foregroundColor(AppConfig.Colors.textSecondary)

                                        Text("Support")
                                            .font(AppConfig.Fonts.body)
                                            .foregroundColor(AppConfig.Colors.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppConfig.Colors.stroke)
                                    }
                                    .padding(AppConfig.UI.screenPadding - 10)
                                }

                                Divider().padding(.leading, 50)

                                Button(action: {
                                    HapticManager.shared.trigger(.warning)
                                    showDeleteAlert = true
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "trash.fill")
                                            .frame(width: 24)
                                            .foregroundColor(.red.opacity(0.8))

                                        Text("Delete Account")
                                            .font(AppConfig.Fonts.body)
                                            .foregroundColor(.red)

                                        Spacer()
                                    }
                                    .padding(16)
                                }
                            }
                            //                        .background(Color.white)
                            .glassEffect(.clear, in: .rect)
                            .cornerRadius(AppConfig.UI.cornerRadius)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            showLogoutAlert = true
                        }) {
                            Text("Log Out")
                                .font(AppConfig.Fonts.headline)
                                .foregroundColor(AppConfig.Colors.alert)
                                .padding()
                                .frame(maxWidth: .infinity)
                                //                            .background(Color.white)
                                .glassEffect(.clear, in: .rect)
                                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                                )
                        }
                        .padding(AppConfig.UI.padding)
                        .padding(.bottom, 30)
                    }
                } else {
                    ProgressView()
                }
            }
            .standardBackground()
            .scrollIndicators(.hidden)
            //            .navigationTitle("Profile")
            .onAppear {
                let patientId = KeychainManager.shared.getString(key: .documentID) ?? appState.currentUser?.id ?? ""
                if !patientId.isEmpty {
                    Task {
                        await quizViewModel.fetchMemoryReports(patientId: patientId)
                    }
                }
            }
            .alert("Copied", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Patient ID has been copied to clipboard.")
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    try? AuthService.shared.signOut()
                    appState.currentUser = nil
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } message: {
                Text("This action is permanent and cannot be undone. All your data will be deleted.")
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete Account", role: .destructive) {
                    if deleteConfirmationText == "DELETE" {
                        deleteAccount()
                    }
                    deleteConfirmationText = ""
                }
            } message: {
                Text("Please type DELETE to permanently delete your account.")
            }
            .sheet(isPresented: $showMemoryCheck) {
                if let patient = appState.currentUser, let id = patient.id {
                    MemoryQuizView()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func deleteAccount() {
        let documentId = KeychainManager.shared.getString(key: .documentID) ?? appState.currentUser?.id ?? ""
        guard !documentId.isEmpty else { return }
        isDeleting = true
        Task {
            do {
                try await AuthService.shared.deleteAccount(documentId: documentId)
                await MainActor.run {
                    isDeleting = false
                    appState.currentUser = nil
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(AppConfig.Fonts.headline)
            .foregroundColor(AppConfig.Colors.textPrimary)
            .padding(.leading, 4)
    }
}

struct InfoTile: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = AppConfig.Colors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .padding(8)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                Text(value)
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(AppConfig.Colors.textPrimary)
            }
        }
        .padding(AppConfig.UI.screenPadding - 10)
        //        .background(Color.white)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppConfig.Colors.stroke)
            }
            .padding(AppConfig.UI.screenPadding - 10)
        }
    }
}

#Preview {
    ProfileView()
}
