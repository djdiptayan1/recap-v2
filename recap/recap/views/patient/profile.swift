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

    // MOCK DATA for UI Development
    // In real app: @StateObject or @EnvironmentObject
    let patient = patientModel(
        firstName: "Robert",
        lastName: "Smith",
        patientUID: "A8X-92B",
        dateOfBirth: "12/04/1952",
        sex: "Male",
        bloodGroup: "O+",
        stage: "Early",
        profileImageURL: "https://media.licdn.com/dms/image/v2/D5603AQHdhQfpvbsi2g/profile-displayphoto-scale_200_200/B56ZkY4WKdHAAY-/0/1757059050148?e=2147483647&v=beta&t=rKD0_vWVUwPDIJrz4o2AhqMytGcygOnKLmUVWbqaOzg",
        email: "robert.smith@gmail.com",
        id: "123"
    )

    @State private var showLogoutAlert = false
    @State private var showCopyAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 110, height: 110)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                            WebImage(url: URL(string: patient.profileImageURL!))
                                .resizable()
                                .indicator(.activity)
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .foregroundColor(Color.gray.opacity(0.3))
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
                    .shadow(color: AppConfig.Colors.accent.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Medical Details")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InfoTile(icon: "calendar", title: "Birth Date", value: patient.dateOfBirth)
                            InfoTile(icon: "drop.fill", title: "Blood Type", value: patient.bloodGroup, iconColor: .red)
                            InfoTile(icon: "person.text.rectangle", title: "Sex", value: patient.sex)
                            InfoTile(icon: "chart.bar.fill", title: "Stage", value: patient.stage, iconColor: .orange)
                        }
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding - 10)

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Health & Settings")

                        VStack(spacing: 0) {
                            SettingsRow(icon: "brain.head.profile", title: "Memory Check", subtitle: "Last check: 2 days ago") {
                                showMemoryCheck = true
                            }

                            Divider().padding(.leading, 50)

                            // Citations Link
                            SettingsRow(icon: "text.book.closed", title: "Medical Citations", subtitle: "View sources") {
                                // Navigation logic
                            }

                            Divider().padding(.leading, 50)

                            Button(action: {}) {
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

                    Button(action: { showLogoutAlert = true }) {
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
            }
            .standardBackground()
            .scrollIndicators(.hidden)
//            .navigationTitle("Profile")
            .alert("Copied", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Patient ID has been copied to clipboard.")
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    appState.isLoggedIn = false
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .sheet(isPresented: $showMemoryCheck) {
                MemoryCheckView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
