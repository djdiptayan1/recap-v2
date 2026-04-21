//
//  patientSignup.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

import SwiftUI

struct patientSignupView: View {
    @StateObject private var viewModel: PatientSignupViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    // Visibility Toggles
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false

    // Initializer to pass data into ViewModel
    init(socialUser: SocialUserData? = nil) {
        _viewModel = StateObject(wrappedValue: PatientSignupViewModel(socialUser: socialUser))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            Image("recapLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .shadow(
                                    color: AppConfig.Colors.accent.opacity(0.3), radius: 15, x: 0,
                                    y: 10
                                )
                                .accessibilityHidden(true)

                            VStack(spacing: 6) {
                                Text(
                                    viewModel.currentStep == .credentials
                                        ? "Create Account" : "Tell us about you"
                                )
                                .font(AppConfig.Fonts.titleLarge)
                                .foregroundColor(AppConfig.Colors.textPrimary)

                                Text(
                                    viewModel.currentStep == .credentials
                                        ? "Begin your memory journey today"
                                        : "Help us personalize your experience"
                                )
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                        VStack(spacing: 20) {
                            ZStack(alignment: .top) {
                                if viewModel.currentStep == .credentials {
                                    credentialsForm
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)
                                            ))
                                }

                                if viewModel.currentStep == .details {
                                    detailsForm
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)
                                            ))
                                }

                                if viewModel.currentStep == .imageUpload {
                                    imageUploadForm
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)
                                            ))
                                }
                            }
                            .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)

                            if let error = viewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .transition(.opacity)
                            }

                            Button(action: {
                                HapticManager.shared.trigger(.selection)
                                viewModel.handlePrimaryAction()
                            }) {
                                ZStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .glassEffect(
                                                .regular,
                                                in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                                    } else {
                                        if viewModel.currentStep == .credentials {
                                            Text("Create Account")
                                                .font(AppConfig.Fonts.headline)
                                        } else if viewModel.currentStep == .details {
                                            Text("Next Step")
                                                .font(AppConfig.Fonts.headline)
                                        } else {
                                            Text("Complete Setup")
                                                .font(AppConfig.Fonts.headline)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppConfig.Colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppConfig.UI.cornerRadius)
                                .shadow(
                                    color: AppConfig.Colors.accent.opacity(0.4), radius: 10, x: 0,
                                    y: 5)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        .animation(.spring(), value: viewModel.currentStep)

                        Spacer().frame(height: 40)

                        if viewModel.currentStep == .credentials {
                            HStack {
                                Text("Already have an account?")
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)

                                Button("Log In") {
                                    dismiss()
                                }
                                .font(AppConfig.Fonts.bodyBold)
                                .foregroundColor(AppConfig.Colors.accent)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .onChange(of: viewModel.showAlert) { newValue in
                if newValue {
                    HapticManager.shared.trigger(.error)
                }
            }
            .onChange(of: viewModel.signedInUser) { user in
                if let user = user {
                    // Update global app state using MainActor
                    Task { @MainActor in
                        HapticManager.shared.trigger(.success)
                        appState.currentUser = user
                        // The Root view will automatically switch to patientTabbar due to appState change
                        // We don't need manual navigation here.
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    var credentialsForm: some View {
        VStack(spacing: 20) {
            // Email
            AestheticInput(
                icon: "envelope.fill",
                placeholder: "Email Address",
                text: $viewModel.email,
                isPasswordVisible: .constant(false)
            )

            // Password
            AestheticInput(
                icon: "lock.fill",
                placeholder: "Password (min 6 chars)",
                text: $viewModel.password,
                isSecure: true,
                showToggle: true,
                isPasswordVisible: $isPasswordVisible
            )

            // Confirm Password
            AestheticInput(
                icon: "lock.shield.fill",
                placeholder: "Confirm Password",
                text: $viewModel.confirmPassword,
                isSecure: true,
                showToggle: true,
                isPasswordVisible: $isConfirmVisible
            )
        }
    }

    var detailsForm: some View {
        VStack(spacing: 20) {
            if viewModel.socialUser != nil {
                importedIdentitySummary
            }

            HStack(spacing: 12) {
                AestheticInput(
                    icon: "person.fill",
                    placeholder: "First Name",
                    text: $viewModel.firstName,
                    isPasswordVisible: .constant(false)
                )

                AestheticInput(
                    icon: "",
                    placeholder: "Last Name",
                    text: $viewModel.lastName,
                    isPasswordVisible: .constant(false)
                )
            }

            // Date of Birth
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .padding(.leading, 4)

                DatePicker("", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.automatic)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(AppConfig.UI.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                            .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                    )
            }

            // Pickers Row
            HStack(spacing: 12) {
                // Sex
                Menu {
                    ForEach(viewModel.sexOptions, id: \.self) { option in
                        Button(option) { viewModel.sex = option }
                    }
                } label: {
                    HStack {
                        Text(viewModel.sex.isEmpty ? "Sex" : viewModel.sex)
                            .foregroundColor(
                                viewModel.sex.isEmpty ? .gray : AppConfig.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(AppConfig.UI.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                            .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                    )
                }

                // Blood Group
                Menu {
                    ForEach(viewModel.bloodGroups, id: \.self) { group in
                        Button(group) { viewModel.bloodGroup = group }
                    }
                } label: {
                    HStack {
                        Text(viewModel.bloodGroup.isEmpty ? "Blood" : viewModel.bloodGroup)
                            .foregroundColor(
                                viewModel.bloodGroup.isEmpty ? .gray : AppConfig.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(AppConfig.UI.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                            .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                    )
                }
            }

            // Stage
            VStack(alignment: .leading, spacing: 8) {
                Text("Stage")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .padding(.leading, 4)

                Picker("Stage", selection: $viewModel.stage) {
                    ForEach(viewModel.stages, id: \.self) { stage in
                        Text(stage).tag(stage)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Image Upload Form

    var imageUploadForm: some View {
        VStack(spacing: 24) {
            Text("Add a Profile Photo")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            ImagePicker(selectedImage: $viewModel.profileImage)

            Text("Tap to select a photo from your library")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
        .padding(.vertical, 20)
    }

    var importedIdentitySummary: some View {
        let providerName = viewModel.socialUser?.provider.displayName ?? "social login"
        let providerIcon = viewModel.socialUser?.provider == .apple ? "applelogo" : "person.crop.circle"
        let importedName = "\(viewModel.socialUser?.firstName ?? "") \(viewModel.socialUser?.lastName ?? "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 12) {
            Label("Imported from \(providerName)", systemImage: providerIcon)
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                Text(importedName.isEmpty ? "No name was shared with \(providerName)." : importedName)
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Text("Email")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .padding(.top, 4)
                Text(viewModel.resolvedEmail.isEmpty ? "\(providerName) provided your sign-in email" : viewModel.resolvedEmail)
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )

            Text("We'll keep the imported email from \(providerName), and you can edit your name before continuing.")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    patientSignupView()
}
