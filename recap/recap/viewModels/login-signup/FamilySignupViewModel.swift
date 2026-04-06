//
//  FamilySignupViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 01/01/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class FamilySignupViewModel: ObservableObject {
    enum SignupStep {
        case details
        case imageUpload
    }

    // Initial Data (Passed from Login)
    var googleUser: GoogleUserData?
    @Published var patientDocumentId = ""
    @Published var patientUID = ""

    // Step: Details
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""  // Read-only mostly
    @Published var phone = ""
    @Published var relation = "Spouse"

    // Step: Avatar
    @Published var profileImage: UIImage?
    // If google has image, we might use it, but user can override.
    // We can store the URL and if profileImage is nil, rely on URL?
    // Or download it? For simplicity, we just use local image if picked, else send google URL string or empty.

    // State
    @Published var currentStep: SignupStep = .details
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAlert = false

    // Navigation (Triggers AppState update in View)
    @Published var signedInUser: patientModel?

    // Data Sources
    let relations = ["Spouse", "Child", "Parent", "Sibling", "Friend", "Caregiver", "Other"]

    init(googleUser: GoogleUserData?, patientDocumentId: String, patientUID: String) {
        self.googleUser = googleUser
        self.patientDocumentId = patientDocumentId
        self.patientUID = patientUID

        if let user = googleUser {
            let components = user.name.components(separatedBy: " ")
            if let first = components.first {
                self.firstName = first
            }
            if components.count > 1 {
                self.lastName = components.dropFirst().joined(separator: " ")
            }
            self.email = user.email
            // We could try to load the image or just use the URL string when creating the profile
        }
    }

    // MARK: - Actions

    func handlePrimaryAction() {
        switch currentStep {
        case .details:
            completeDetails()
        case .imageUpload:
            finalizeSignup()
        }
    }

    func completeDetails() {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !phone.isEmpty, !relation.isEmpty
        else {
            showError("Please fill in first name, last name, phone, and relation.")
            return
        }

        withAnimation {
            self.currentStep = .imageUpload
        }
    }

    //    func skipImageUpload() {
    //         finalizeSignup()
    //    }

    func finalizeSignup() {
        isLoading = true

        // Prepare Image
        // If user picked an image, convert to Base64.
        // If not, we might check if Google User had a photo URL and pass that?
        // The Service expects Base64 or we need to update service to accept URL.
        // The service `createFamilyUser` (or `createFamilyProfile`) endpoint might handle URL logic?
        // Let's stick to Base64 upload for custom image.
        // If no custom image, validation in backend handles default or we send empty.

        var profileImageBase64: String = ""
        if let image = profileImage,
            let imageData = image.jpegData(compressionQuality: 0.8)
        {
            profileImageBase64 = imageData.base64EncodedString()
        }

        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

        let request = FamilySignupRequest(
            patient_documentId: patientDocumentId,
            email: email,
            name: fullName,
            profileImageBase64: profileImageBase64,
            profileImageURL: profileImage == nil ? googleUser?.profileImageURL : nil,
            phone: phone,
            relation: relation
        )

        Task {
            do {
                // 1. Create Profile in Backend
                let response = try await FamilySignupService.shared.createFamilyProfile(
                    request: request)

                guard response.success, let data = response.data else {
                    throw NSError(
                        domain: "Signup", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: response.message])
                }

                // 2. Construct User Model from Response
                // We trust the backend response which has the canonical ID and image URL

                // Save Keychain
                try KeychainManager.shared.save(key: .documentID, value: data.id)
                try KeychainManager.shared.save(key: .familyDocumentID, value: data.id)
                try KeychainManager.shared.save(key: .patientUID, value: patientUID)
                try KeychainManager.shared.save(key: .userType, value: "family")

                if !patientDocumentId.isEmpty {
                    try KeychainManager.shared.save(
                        key: .patientDocumentID, value: patientDocumentId)
                }

                AnalyticsManager.shared.logSignUp(method: "google")

                // Construct patientModel
                // Note: We might be missing `linkedPatient` data here compared to `verifyFamilyMember` response.
                // However, `patientModel` usually needs basic info.
                // If we absolutely need the linkedPatient object, we might need to fetch it or create a placeholder.
                // Since this is just for the initial session state, and we have patientUID/DocumentId, it should be fine.
                // We'll create a minimal linked patient object if needed or just leave it nil/basic.

                var familyUser = patientModel(
                    firstName: data.name,
                    lastName: "",
                    patientUID: patientUID,
                    dateOfBirth: "",
                    sex: "",
                    bloodGroup: "",
                    stage: "",
                    profileImageURL: data.imageURL,
                    email: data.email,
                    id: data.id,
                    type: "family",
                    familyMembers: []
                )
                familyUser.relation = data.relation
                familyUser.phone = data.phone

                // Ideally, we'd have the linked patient info.
                // For now, let's proceed. The app can fetch patient details on demand using the ID we saved.

                await MainActor.run {
                    self.isLoading = false
                    self.signedInUser = familyUser
                }

            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError("Signup failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // Helpers
    private func showError(_ message: String) {
        self.errorMessage = message
        self.showAlert = true
    }
}
