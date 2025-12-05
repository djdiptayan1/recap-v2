//
//  patientLogin.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation

class PatientAuthService {
    static let shared = PatientAuthService()
    private init() {}
    
    func signIn(email: String, password: String) async throws -> patientModel {
        return try await AuthService.shared.signIn(email: email, password: password)
    }
    
    func signInWithGoogle() async throws -> patientModel {
        return try await AuthService.shared.signInWithGoogle()
    }
}
