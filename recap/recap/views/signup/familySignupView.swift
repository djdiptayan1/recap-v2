//
//  familySignupView.swift
//  recap
//
//  Created by Diptayan Jash on 01/01/26.
//

import SwiftUI

struct familySignupView: View {
    @StateObject private var viewModel: FamilySignupViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    // Initializer to pass data into ViewModel
    init(socialUser: SocialUserData?, patientDocumentId: String, patientUID: String) {
        _viewModel = StateObject(
            wrappedValue: FamilySignupViewModel(
                socialUser: socialUser,
                patientDocumentId: patientDocumentId,
                patientUID: patientUID
            ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            if let profileImage = viewModel.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(
                                        color: AppConfig.Colors.accent.opacity(0.3), radius: 10,
                                        x: 0, y: 5)
                            } else if let urlString = viewModel.socialUser?.profileImageURL,
                                let url = URL(string: urlString)
                            {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(
                                            AppConfig.Colors.textSecondary.opacity(0.3))
                                }
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(
                                    color: AppConfig.Colors.accent.opacity(0.3), radius: 10, x: 0,
                                    y: 5)
                            } else {
                                Image("recapLogo")  // Fallback
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                            }

                            VStack(spacing: 6) {
                                Text(headerTitle)
                                    .font(AppConfig.Fonts.titleLarge)
                                    .foregroundColor(AppConfig.Colors.textPrimary)

                                Text(headerSubtitle)
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                        VStack(spacing: 20) {
                            ZStack(alignment: .top) {
                                if viewModel.currentStep == .details {
                                    detailsForm
                                        .transition(.move(edge: .leading))
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
                                        Text(buttonTitle)
                                            .font(AppConfig.Fonts.headline)
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

                            // Skip button for image upload
                            //                            if viewModel.currentStep == .imageUpload {
                            //                                Button("Use Google Photo / Skip") {
                            //                                    viewModel.skipImageUpload()
                            //                                }
                            //                                .font(AppConfig.Fonts.body)
                            //                                .foregroundColor(AppConfig.Colors.textSecondary)
                            //                                .padding(.top, 8)
                            //                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        .animation(.spring(), value: viewModel.currentStep)

                        Spacer().frame(height: 40)
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
                    }
                }
            }
        }
    }

    // MARK: - Dynamic Text Helpers

    var headerTitle: String {
        switch viewModel.currentStep {
        case .details: return "Final Details"
        case .imageUpload: return "Profile Photo"
        }
    }

    var headerSubtitle: String {
        switch viewModel.currentStep {
        case .details: return "Almost there! Just a few more things."
        case .imageUpload: return "Update your photo if you like."
        }
    }

    var buttonTitle: String {
        switch viewModel.currentStep {
        case .details: return "Next"
        case .imageUpload: return "Complete Setup"
        }
    }

    // MARK: - Subviews

    var detailsForm: some View {
        VStack(spacing: 20) {
            if viewModel.socialUser != nil {
                importedIdentitySummary
            }

            AestheticInput(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $viewModel.email,
                isPasswordVisible: .constant(false)
            )
            .disabled(true)
            .opacity(0.8)

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

            // Phone
            AestheticInput(
                icon: "phone.fill",
                placeholder: "Phone Number",
                text: $viewModel.phone,
                isPasswordVisible: .constant(false)
            )
            .keyboardType(.phonePad)

            // Relation
            VStack(alignment: .leading, spacing: 8) {
                Text("Relationship to Patient")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .padding(.leading, 4)

                Menu {
                    ForEach(viewModel.relations, id: \.self) { relation in
                        Button(relation) { viewModel.relation = relation }
                    }
                } label: {
                    HStack {
                        Text(
                            viewModel.relation.isEmpty ? "Select Relationship" : viewModel.relation
                        )
                        .foregroundColor(
                            viewModel.relation.isEmpty ? .gray : AppConfig.Colors.textPrimary)
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
        }
    }

    // MARK: - Image Upload Form

    var imageUploadForm: some View {
        VStack(spacing: 24) {
            Text("Update Profile Photo")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            ImagePicker(selectedImage: $viewModel.profileImage)

            Text("Tap to select a new photo")
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
                Text(viewModel.resolvedEmail)
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

            Text("We'll keep the imported email from \(providerName), and you can edit the name before continuing.")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    familySignupView(
        socialUser: SocialUserData(
            uid: "social-uid",
            email: "test@gmail.com",
            firstName: "Test",
            lastName: "User",
            profileImageURL: nil,
            provider: .google),
        patientDocumentId: "123", patientUID: "123456"
    )
    .environmentObject(AppState())
}
