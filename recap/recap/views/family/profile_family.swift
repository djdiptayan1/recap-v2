//
//  profile_family.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import SDWebImageSwiftUI
import SwiftUI

struct ProfileFamilyView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var quizViewModel = MemoryQuizViewModel()
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showDeleteError = false
    @State private var isDeleting = false

    var body: some View {
        let documentID =
            KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?.id
            ?? ""
        NavigationStack {
            ScrollView {
                if let familyMember = appState.currentUser {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemBackground))
                                    .frame(width: 110, height: 110)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                                if let profileImageURL = familyMember.profileImageURL,
                                    let url = URL(
                                        string: CloudinaryUtility.optimize(
                                            profileImageURL, transform: .avatar))
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
                                Text("\(familyMember.firstName) \(familyMember.lastName)")
                                    .font(AppConfig.Fonts.titleMedium)
                                    .foregroundColor(AppConfig.Colors.textPrimary)

                                Text(familyMember.email)
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Family Details")

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16
                            ) {
                                InfoTile(
                                    icon: "person.2.fill", title: "Relation",
                                    value: familyMember.relation ?? "N/A")
                                InfoTile(
                                    icon: "phone.fill", title: "Phone",
                                    value: familyMember.phone ?? "N/A", iconColor: .green)
                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                        if let patient = familyMember.linkedPatient {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Patient Details")

                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 16
                                ) {
                                    InfoTile(
                                        icon: "person.fill", title: "Name",
                                        value: "\(patient.firstName) \(patient.lastName)")
                                    InfoTile(
                                        icon: "number", title: "Patient UID",
                                        value: patient.patientUID, iconColor: .blue)

                                    // if let latestReport = quizViewModel.reports.first {
                                    //     NavigationLink(
                                    //         destination: MemoryQuizHistoryListView(
                                    //             reports: quizViewModel.reports)
                                    //     ) {
                                    //         InfoTile(
                                    //             icon: latestReport.safeIcon,
                                    //             title: "Latest Check",
                                    //             value: latestReport.safeStatus,
                                    //             iconColor: latestReport.swiftColor
                                    //         )
                                    //     }
                                    //     .buttonStyle(PlainButtonStyle())
                                    // }
                                }
                            }
                            .padding(.horizontal, AppConfig.UI.screenPadding - 10)
                            .onAppear {
                                Task {
                                    await quizViewModel.fetchMemoryReports(
                                        patientId: documentID)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Settings")

                            VStack(spacing: 0) {
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
                                .glassEffect(.regular, in: .rect)
                                .cornerRadius(AppConfig.UI.cornerRadius)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
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
                                .glassEffect(.regular, in: .rect)
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
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    DataPrefetchManager.shared.invalidateAll()
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
                Text(
                    "This action is permanent and cannot be undone. All your data will be deleted.")
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete Account", role: .destructive) {
                    if deleteConfirmationText == "DELETE" {
                        deleteAccount()
                    } else {
                        showDeleteError = true
                    }
                    deleteConfirmationText = ""
                }
            } message: {
                Text("Please type DELETE to permanently delete your account.")
            }
            .alert("Incorrect Confirmation", isPresented: $showDeleteError) {
                Button("Try Again", role: .cancel) {
                    showDeleteConfirmation = true
                }
            } message: {
                Text("You must type DELETE exactly to confirm account deletion.")
            }
        }
    }

    private func deleteAccount() {
        let documentId =
            KeychainManager.shared.getString(key: .documentID) ?? appState.currentUser?.id ?? ""
        guard !documentId.isEmpty else { return }
        isDeleting = true
        Task {
            do {
                try await AuthService.shared.deleteAccount(documentId: documentId)
                await MainActor.run {
                    DataPrefetchManager.shared.invalidateAll()
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

struct QuizHistoryRow: View {
    let report: MemoryReport

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(report.swiftColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: report.safeIcon)
                    .font(.system(size: 20))
                    .foregroundColor(report.swiftColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(report.safeStatus)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                // Assuming date is string for now, user can format if needed
                Text(formatDate(dateString: report.date))
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(report.safeTotalScore)/\(report.safeTotalQuestions)")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(report.swiftColor)

                Text("Score")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(report.safeStatus). Score: \(report.safeTotalScore) out of \(report.safeTotalQuestions). Date: \(formatDate(dateString: report.date))"
        )
    }

    // Helper to try formatting the date string nicely
    func formatDate(dateString: String) -> String {
        // If string is already readable, return it.
        // If it's ISO, format it.
        // For this specific iteration, we'll return as is or improve parsing if we knew the exact format of the JSON response string from backend.
        // The backend uses native Firestore serialization in `doc.data()`, so timestamps might need detailed parsing.
        // For MVP, just returning string.
        return dateString
    }
}

#Preview {
    ProfileFamilyView()
}
