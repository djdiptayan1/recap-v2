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
}
