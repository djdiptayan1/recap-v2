//
//  PatientSignupViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class PatientSignupViewModel: ObservableObject {
    enum SignupStep {
        case credentials
        case details
        case imageUpload
    }

    // Step 1: Credentials
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    // Step 2: Details
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = Date()
    @Published var bloodGroup = "A+"
    @Published var sex = "Male"
    @Published var stage = "Early"

    // Step 3: Avatar
    @Published var profileImage: UIImage?

    // State
    @Published var currentStep: SignupStep = .credentials
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAlert = false

    // Navigation
    @Published var signedInUser: patientModel?  // Used to trigger AppState update
    @Published var showImageUpload = false  // Used for internal flow (image step)

    // Data Sources
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    let sexOptions = ["Male", "Female", "Other"]
    let stages = ["Early", "Middle", "Late"]

    private var userId: String?

    // MARK: - Actions

    func handlePrimaryAction() {
        switch currentStep {
        case .credentials:
            createAccount()
        case .details:
            completeProfile()
        case .imageUpload:
            finalizeSignup()
        }
    }

    func createAccount() {
        // Validation
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showError("Please fill in all fields.")
            return
        }

        guard isValidEmail(email) else {
            showError("Please enter a valid email address.")
            return
        }

        guard password.count >= 6 else {
            showError("Password must be at least 6 characters.")
            return
        }

        guard password == confirmPassword else {
            showError("Passwords do not match.")
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let user = try await AuthService.shared.signup(email: email, password: password)
                self.userId = user.uid
                self.isLoading = false
                // Move to next step
                withAnimation {
                    self.currentStep = .details
                }
            } catch {
                self.isLoading = false
                self.showError(error.localizedDescription)
            }
        }
    }

    func completeProfile() {
        // Validation
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            showError("Please enter your first and last name.")
            return
        }

        // Move to image upload step
        withAnimation {
            self.currentStep = .imageUpload
        }
    }

    func finalizeSignup() {
        guard let uid = userId else {
            showError("User ID not found. Please try again.")
            return
        }

        guard !firstName.isEmpty, !lastName.isEmpty else {
            showError("Please enter your name.")
            return
        }

        isLoading = true

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dobString = formatter.string(from: dateOfBirth)

        var profileImageBase64: String? = nil
        if let image = profileImage,
            let imageData = image.jpegData(compressionQuality: 0.8)
        {
            profileImageBase64 = imageData.base64EncodedString()
        }

        let request = PatientSignupRequest(
            uid: uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dobString,
            bloodGroup: bloodGroup,
            sex: sex,
            stage: stage,
            profileImageBase64: profileImageBase64 ?? ""
        )

        Task {
            do {
                // 1. Create Profile in Backend
                try await PatientSignupService.shared.createPatientProfile(request: request)

                // 2. Auto-Login (Fetch full user model & save to Keychain)
                // We use the already known credentials
                let user = try await AuthService.shared.signIn(email: email, password: password)

                // 3. Mark as verified locally (redundant with login but safe)
                UserDefaults.standard.set(uid, forKey: "verifiedUserDocID")

                // 4. Trigger Navigation via AppState (by setting signedInUser)
                await MainActor.run {
                    self.isLoading = false
                    self.signedInUser = user
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

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
