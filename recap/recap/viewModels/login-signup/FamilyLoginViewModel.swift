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
import FirebaseCore

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
    var pendingSocialUser: SocialUserData?

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
                let parsedName = Self.splitDisplayName(user.displayName)
                pendingSocialUser = SocialUserData(
                    uid: user.uid,
                    email: email,
                    firstName: parsedName.firstName,
                    lastName: parsedName.lastName,
                    profileImageURL: user.photoURL?.absoluteString,
                    provider: .google
                )
                showSignupSheet = true
                return nil
            }
            
        } catch let error as NetworkError {
            // Handle 404 (Not Found) specifically to trigger signup
            if case .httpError(let statusCode) = error, statusCode == 404 {
                let parsedName = Self.splitDisplayName(user.displayName)
                pendingSocialUser = SocialUserData(
                    uid: user.uid,
                    email: email,
                    firstName: parsedName.firstName,
                    lastName: parsedName.lastName,
                    profileImageURL: user.photoURL?.absoluteString,
                    provider: .google
                )
                showSignupSheet = true
                return nil
            }
            throw error
        } catch {
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
        
        AnalyticsManager.shared.logLogin(method: "social")
        
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

    func finalizeAppleLogin(response: VerifyFamilyMemberResponse, email: String) async throws -> patientModel {
        return try await finalizeLogin(response: response, email: email)
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
}
