//
//  PatientLoginView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct PatientLoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PatientLoginViewModel()

    var body: some View {
        VStack {

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Image("recapLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 15, x: 0, y: 10)

                        VStack(spacing: 6) {
                            Text("Welcome Back")
                                .font(AppConfig.Fonts.titleLarge)
                                .foregroundColor(AppConfig.Colors.textPrimary)

                            Text("Sign in to access your health journal")
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    VStack(spacing: 20) {
                        AestheticInput(
                            icon: "envelope.fill",
                            placeholder: "Email address",
                            text: $viewModel.email,
                            isPasswordVisible: .constant(false)
                        )

                        VStack(alignment: .trailing, spacing: 8) {
                            AestheticInput(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $viewModel.password,
                                isSecure: true,
                                showToggle: true,
                                isPasswordVisible: $viewModel.showPassword
                            )

                            Button("Forgot Password?") {
                                // Action
                            }
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        }

                        Button(action: loginWithEmail) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 5)
                                }
                                Text("Log In")
                                    .font(AppConfig.Fonts.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppConfig.Colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(AppConfig.UI.cornerRadius)
                            .shadow(color: AppConfig.Colors.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding)

                    HStack {
                        Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
                        Text("or continue with")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 40)

                    VStack(spacing: 16) {
                        // Google
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image("google")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Sign in with Google")
                                    .font(AppConfig.Fonts.bodyBold)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(AppConfig.UI.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        .frame(height: 56)
                        .cornerRadius(AppConfig.UI.cornerRadius)
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding)

                    Spacer(minLength: 40)

                    HStack {
                        Text("Don't have an account?")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)

                        Button("Sign Up") {
                            viewModel.showSignupSheet = true
                        }
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(AppConfig.Colors.accent)
                    }
                    .padding(.bottom, 20)
                }
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $viewModel.showSignupSheet) {
                patientSignupView()
            }
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
        .standardBackground()
    }

    // MARK: - Logic Functions
    
    private func loginWithEmail() {
        Task {
            if let user = await viewModel.loginWithEmail() {
                await MainActor.run {
                    appState.currentUser = user
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        Task {
            if let user = await viewModel.signInWithGoogle() {
                await MainActor.run {
                    appState.currentUser = user
                }
            }
        }
    }
    
    private func handleAppleSignInCompletion() {
    }
    
    private func fetchOrCreateUserProfile(userId: String, email: String) {
    }
    
    private func generateAndCreateProfile(userId: String, email: String) {
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PatientLoginView()
//        .environmentObject(AppState())
}
