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

struct GoogleUserData {
    let email: String
    let name: String
    let profileImageURL: String?
}

@MainActor
class FamilyLoginViewModel: ObservableObject {
    @Published var patientUID = ""
    @Published var isVerified = false
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    @Published var patientDocumentId = ""
    @Published var showSignupSheet = false
    
    // Data to pass to Signup
    var pendingGoogleUser: GoogleUserData?

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
    
    func signInWithGoogle() async throws -> patientModel? {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Perform Google Sign-In
        let (user, email) = try await AuthService.shared.performGoogleSignIn()
        
        // 2. Verify Family Member Link
        do {
            let response = try await authService.verifyFamilyMember(email: email, documentId: patientDocumentId)
            
            if response.success {
                // LINK EXISTS -> LOGIN SUCCESS
                return try await finalizeLogin(response: response, email: email)
            } else {
                // LINK NOT FOUND -> PROMPT SIGNUP
                // Store data for the signup form
                pendingGoogleUser = GoogleUserData(
                    email: email,
                    name: user.displayName ?? "",
                    profileImageURL: user.photoURL?.absoluteString
                )
                showSignupSheet = true
                return nil
            }
            
        } catch {
             // If verify fails strictly (network error etc), throw.
             // But if it fails because "not found" (404/409 logic in service?), we might need to handle it.
             // Assuming verifyFamilyMember returns success=false if not found but no error thrown if 200 OK with success=false.
             // If the service throws on 404, we catch it here.
             
             // Quick fix: Check if error is "not found" type or just proceed to signup?
             // Safest is to rely on success bool if service suppresses error, or catch specific error.
             // Assuming service returns VerifyFamilyMemberResponse with success=false for non-existence.
             throw error
        }
    }
    
    private func finalizeLogin(response: VerifyFamilyMemberResponse, email: String) async throws -> patientModel {
        // Save to Keychain
         if let familyId = response.familymember_documentId {
             try KeychainManager.shared.save(key: .documentID, value: familyId)
             try KeychainManager.shared.save(key: .familyDocumentID, value: familyId)
         }
         
         try KeychainManager.shared.save(key: .patientUID, value: patientUID)
         
         if !patientDocumentId.isEmpty {
             try KeychainManager.shared.save(key: .patientDocumentID, value: patientDocumentId)
         }
        
         try KeychainManager.shared.save(key: .userType, value: "family")
        
        var familyUser = patientModel(
            firstName: response.name ?? "Family Member",
            lastName: "",
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
    }
}
