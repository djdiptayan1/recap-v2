//
//  FamilyLoginViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@MainActor
class FamilyLoginViewModel: ObservableObject {
    @Published var patientUID = ""
    @Published var isVerified = false
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    @Published var patientDocumentId = ""

    private let authService = FamilyAuthService.shared
    
    func verifyPatientUID() {
        guard patientUID.count == 6 else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await authService.verifyPatientUID(patientUID)
                if response.success && response.exists {
                    isVerified = true
                    if let docId = response.documentId {
                        patientDocumentId = docId
                    }
                } else {
                    alertMessage = response.message
                    showAlert = true
                }
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
    }
    
    func resetVerification() {
        isVerified = false
        patientUID = ""
        patientDocumentId = ""
    }
    
    func signInWithGoogle() async throws -> patientModel {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Perform Google Sign-In using the shared helper
        let (user, email) = try await AuthService.shared.performGoogleSignIn()
        
        // 2. Verify Family Member
        do {
            let response = try await authService.verifyFamilyMember(email: email, documentId: patientDocumentId)
            
            if response.success {
                // Create patientModel from response
                // Note: We might need to fetch the full patient details or just use what we have.
                // The response gives us family member details.
                // We need to construct a user object that the app understands.
                // Since the app expects a `patientModel` (which is actually a User model), we map it.
                
                var familyUser = patientModel(
                    firstName: response.name ?? "Family Member",
                    lastName: "", // Name is usually full name in response
                    patientUID: patientUID,
                    dateOfBirth: "",
                    sex: "",
                    bloodGroup: "",
                    stage: "",
                    profileImageURL: response.imageURL,
                    email: email,
                    id: response.familymember_documentId,
                    type: "family",
                    familyMembers: []
                )
                familyUser.relation = response.relation
                familyUser.phone = response.phone
                familyUser.linkedPatient = response.patientdata
                
                return familyUser
            } else {
                throw NSError(domain: "FamilyLogin", code: 401, userInfo: [NSLocalizedDescriptionKey: response.message])
            }
            
        } catch {
            throw error
        }
    }
}
