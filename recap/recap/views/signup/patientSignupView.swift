//
//  patientSignup.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

import SwiftUI

struct patientSignupView: View {
    @StateObject private var viewModel = PatientSignupViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    // Visibility Toggles
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false
    
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
                                .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 15, x: 0, y: 10)
                            
                            VStack(spacing: 6) {
                                Text(viewModel.currentStep == .credentials ? "Create Account" : "Tell us about you")
                                    .font(AppConfig.Fonts.titleLarge)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                
                                Text(viewModel.currentStep == .credentials ? "Begin your memory journey today" : "Help us personalize your experience")
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                        
                        VStack(spacing: 20) {
                            
                            if viewModel.currentStep == .credentials {
                                // STEP 1: CREDENTIALS
                                credentialsForm
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    ))
                            } else if viewModel.currentStep == .details {
                                // STEP 2: DETAILS
                                detailsForm
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    ))
                            } else {
                                // STEP 3: IMAGE UPLOAD
                                imageUploadForm
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    ))
                            }
                            
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
                            
                            Button(action: viewModel.handlePrimaryAction) {
                                ZStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(viewModel.currentStep == .credentials ? "Create Account" : "Complete Setup")
                                            .font(AppConfig.Fonts.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppConfig.Colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppConfig.UI.cornerRadius)
                                .shadow(color: AppConfig.Colors.accent.opacity(0.4), radius: 10, x: 0, y: 5)
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
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .onChange(of: viewModel.signedInUser) { user in
                if let user = user {
                    // Update global app state using MainActor
                    Task { @MainActor in
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
            // Name
            HStack(spacing: 12) {
                AestheticInput(
                    icon: "person.fill",
                    placeholder: "First Name",
                    text: $viewModel.firstName,
                    isPasswordVisible: .constant(false)
                )
                
                AestheticInput(
                    icon: "", // No icon for second field to save space or visual balance
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
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppConfig.Colors.textSecondary)
                    .cornerRadius(AppConfig.UI.cornerRadius)
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
                            .foregroundColor(viewModel.sex.isEmpty ? .gray : AppConfig.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppConfig.Colors.textSecondary)
                    .cornerRadius(AppConfig.UI.cornerRadius)
                }
                
                // Blood Group
                Menu {
                    ForEach(viewModel.bloodGroups, id: \.self) { group in
                        Button(group) { viewModel.bloodGroup = group }
                    }
                } label: {
                    HStack {
                        Text(viewModel.bloodGroup.isEmpty ? "Blood" : viewModel.bloodGroup)
                            .foregroundColor(viewModel.bloodGroup.isEmpty ? .gray : AppConfig.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppConfig.Colors.textSecondary)
                    .cornerRadius(AppConfig.UI.cornerRadius)
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
}

#Preview {
    patientSignupView()
}
