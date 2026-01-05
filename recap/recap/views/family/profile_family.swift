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

    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let familyMember = appState.currentUser {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 110, height: 110)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                                if let profileImageURL = familyMember.profileImageURL,
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
                                }
                            }
                            .padding(.horizontal, AppConfig.UI.screenPadding - 10)
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
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "trash.fill")

                                        Spacer()
                                    }
                                    .padding(16)
                                }
                                .glassEffect(.clear, in: .rect)
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
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    appState.isLoggedIn = false
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

#Preview {
    ProfileFamilyView()
}
