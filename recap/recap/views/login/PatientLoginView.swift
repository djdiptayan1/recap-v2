//
//  PatientLoginView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import AuthenticationServices
import FirebaseAuth
import SwiftUI

struct PatientLoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PatientLoginViewModel()

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    emailPasswordSection
                    dividerSection
                    socialSignInSection
                    Spacer(minLength: 40)
                    footerSection
                }
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $viewModel.showSignupSheet) {
                patientSignupView(socialUser: viewModel.pendingSocialUser)
            }
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Reset Password", isPresented: $viewModel.showForgotPassword) {
            TextField("Email address", text: $viewModel.forgotPasswordEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Send Reset Link") {
                Task { await viewModel.sendPasswordReset() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Email Sent", isPresented: $viewModel.showForgotPasswordSuccess) {
            Button("OK") {}
        } message: {
            Text(viewModel.forgotPasswordMessage)
        }
        .onChange(of: viewModel.showAlert) { newValue in
            if newValue {
                HapticManager.shared.trigger(.error)
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Close keyboard")
                .accessibilityInputLabels(["close keyboard", "dismiss keyboard", "hide keyboard"])
        )
        .standardBackground()
    }

    // MARK: - Extracted Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("recapLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(
                    color: AppConfig.Colors.accent.opacity(0.3), radius: 15, x: 0, y: 10
                )
                .accessibilityHidden(true)

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
    }

    private var emailPasswordSection: some View {
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
                    HapticManager.shared.trigger(.selection)
                    viewModel.forgotPasswordEmail = viewModel.email
                    viewModel.showForgotPassword = true
                }
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .accessibilityInputLabels(["forgot password", "reset password", "password help"])
            }

            loginButton
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var loginButton: some View {
        Button(action: {
            HapticManager.shared.trigger(.selection)
            loginWithEmail()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .glassEffect(
                            .regular,
                            in: .rect(cornerRadius: AppConfig.UI.cornerRadius)
                        )
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
            .shadow(
                color: AppConfig.Colors.accent.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel("Log in")
        .accessibilityInputLabels(["log in", "sign in", "continue"])
    }

    private var dividerSection: some View {
        HStack {
            Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
            Text("or continue with")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
            Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
    }

    private var socialSignInSection: some View {
        VStack(spacing: 16) {
            googleButton
            appleButton
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var googleButton: some View {
        Button(action: {
            HapticManager.shared.trigger(.selection)
            signInWithGoogle()
        }) {
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
        .accessibilityLabel("Sign in with Google")
        .accessibilityInputLabels(["google", "google sign in", "sign in with google"])
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = AuthService.shared.generateNonce()
            request.requestedScopes = [.email, .fullName]
            request.nonce = AuthService.shared.sha256(nonce)
        } onCompletion: { result in
            handleAppleSignInResult(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 56)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .accessibilityLabel("Sign in with Apple")
        .accessibilityInputLabels(["apple", "apple sign in", "sign in with apple"])
    }

    private var footerSection: some View {
        HStack {
            Text("Don't have an account?")
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)

            Button("Sign Up") {
                HapticManager.shared.trigger(.selection)
                viewModel.showSignupSheet = true
            }
            .font(AppConfig.Fonts.bodyBold)
            .foregroundColor(AppConfig.Colors.accent)
            .accessibilityInputLabels(["sign up", "create account", "register"])
        }
        .padding(.bottom, 20)
    }

    // MARK: - Logic Functions

    private func loginWithEmail() {
        Task {
            if let user = await viewModel.loginWithEmail() {
                await MainActor.run {
                    HapticManager.shared.trigger(.success)
                    appState.currentUser = user
                }
            }
        }
    }

    private func signInWithGoogle() {
        Task {
            if let user = await viewModel.signInWithGoogle() {
                await MainActor.run {
                    HapticManager.shared.trigger(.success)
                    appState.currentUser = user
                }
            }
        }
    }

    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let appleIDCredential = authorization.credential
                    as? ASAuthorizationAppleIDCredential,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8),
                let nonce = AuthService.shared.getCurrentNonce()
            else {
                viewModel.alertMessage = "Unable to process Apple Sign-In."
                viewModel.showAlert = true
                return
            }
            Task {
                var appleAuthResult: AppleAuthResult?
                do {
                    let result = try await AuthService.shared.performAppleSignIn(
                        idTokenString: idTokenString,
                        nonce: nonce,
                        appleEmail: appleIDCredential.email,
                        fullName: appleIDCredential.fullName
                    )
                    appleAuthResult = result

                    let userModel = try await AuthService.shared.fetchUser(email: result.email)

                    if let id = userModel.id {
                        try? KeychainManager.shared.save(key: .documentID, value: id)
                        try? KeychainManager.shared.save(key: .patientDocumentID, value: id)
                    }
                    if !userModel.patientUID.isEmpty {
                        try? KeychainManager.shared.save(
                            key: .patientUID, value: userModel.patientUID)
                    }
                    try? KeychainManager.shared.save(key: .userType, value: "patient")

                    await MainActor.run {
                        HapticManager.shared.trigger(.success)
                        appState.currentUser = userModel
                    }
                } catch let error as NSError
                    where error.code == 404
                    || error.localizedDescription.contains("User profile not found")
                {
                    await MainActor.run {
                        if let currentUser = Auth.auth().currentUser {
                            viewModel.pendingSocialUser = SocialUserData(
                                uid: currentUser.uid,
                                email: appleAuthResult?.email ?? currentUser.email ?? "",
                                firstName: appleAuthResult?.firstName ?? "",
                                lastName: appleAuthResult?.lastName ?? "",
                                profileImageURL: currentUser.photoURL?.absoluteString,
                                provider: .apple
                            )
                            viewModel.showSignupSheet = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        viewModel.alertMessage = error.localizedDescription
                        viewModel.showAlert = true
                    }
                }
            }
        case .failure(let error):
            viewModel.alertMessage = error.localizedDescription
            viewModel.showAlert = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PatientLoginView()
    //        .environmentObject(AppState())
}
