//
//  PatientLoginViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Combine
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import SwiftUI

enum SocialAuthProvider {
    case google
    case apple

    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
}

struct SocialUserData {
    let uid: String
    let email: String
    let firstName: String
    let lastName: String
    let profileImageURL: String?
    let provider: SocialAuthProvider

    var name: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

@MainActor
class PatientLoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false

    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showSignupSheet = false
    @Published var pendingSocialUser: SocialUserData?

    // Forgot Password
    @Published var showForgotPassword = false
    @Published var forgotPasswordEmail = ""
    @Published var showForgotPasswordSuccess = false
    @Published var forgotPasswordMessage = ""

    private let authService = PatientAuthService.shared

    func loginWithEmail() async -> patientModel? {
        guard !email.isEmpty, !password.isEmpty else { return nil }
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signIn(email: email, password: password)
            AnalyticsManager.shared.logLogin(method: "email")
            return user
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            return nil
        }
    }

    func signInWithGoogle() async -> patientModel? {
        isLoading = true
        defer { isLoading = false }

        do {
            let (user, email) = try await AuthService.shared.performGoogleSignIn()
            let userModel = try await AuthService.shared.fetchUser(email: email)

            // Save to Keychain if needed (already handled in AuthService ideally, but let's replicate the patientLogin.swift logic)
            if let id = userModel.id {
                try? KeychainManager.shared.save(key: .documentID, value: id)
                try? KeychainManager.shared.save(key: .patientDocumentID, value: id)
            }
            if !userModel.patientUID.isEmpty {
                try? KeychainManager.shared.save(key: .patientUID, value: userModel.patientUID)
            }
            try? KeychainManager.shared.save(key: .userType, value: "patient")

            AnalyticsManager.shared.logLogin(method: "google")
            return userModel
        } catch let error as NSError
            where error.code == 404 || error.localizedDescription.contains("User profile not found")
        {
            // Profile does not exist, trigger signup with pre-filled data
            if let currentUser = Auth.auth().currentUser {
                let parsedName = Self.splitDisplayName(currentUser.displayName)
                self.pendingSocialUser = SocialUserData(
                    uid: currentUser.uid,
                    email: currentUser.email ?? "",
                    firstName: parsedName.firstName,
                    lastName: parsedName.lastName,
                    profileImageURL: currentUser.photoURL?.absoluteString,
                    provider: .google
                )
                self.showSignupSheet = true
            }
            return nil
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            return nil
        }
    }

    private static func splitDisplayName(_ fullName: String?) -> (firstName: String, lastName: String) {
        let trimmed = (fullName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("", "")
        }

        let parts = trimmed.split(separator: " ").map(String.init)
        guard let first = parts.first else {
            return ("", "")
        }

        return (first, parts.dropFirst().joined(separator: " "))
    }

    func sendPasswordReset() async {
        let emailToReset = forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailToReset.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.sendPasswordReset(email: emailToReset)
            forgotPasswordMessage = "A password reset link has been sent to \(emailToReset)"
            showForgotPasswordSuccess = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
