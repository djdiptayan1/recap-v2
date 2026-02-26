//
//  PatientLoginViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PatientLoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showSignupSheet = false
    
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
            let user = try await authService.signInWithGoogle()
            return user
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            return nil
        }
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
