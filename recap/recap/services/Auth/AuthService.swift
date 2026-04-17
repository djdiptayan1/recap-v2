//
//  AuthService.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn

struct AppleAuthResult {
    let user: User
    let email: String
    let firstName: String
    let lastName: String

    var fullName: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()

    // Store the nonce for Apple Sign-In verification
    private var currentNonce: String?

    private init() {}

    // MARK: - Email/Password Login
    func signIn(email: String, password: String) async throws -> patientModel {
        let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = try await fetchUser(email: email)

        // Save to Keychain
        if let id = user.id {
            try? KeychainManager.shared.save(key: .documentID, value: id)
            // For regular patient login, user ID IS the patient document ID
            try? KeychainManager.shared.save(key: .patientDocumentID, value: id)
        }
        if !user.patientUID.isEmpty {
            try? KeychainManager.shared.save(key: .patientUID, value: user.patientUID)
        }

        try? KeychainManager.shared.save(key: .userType, value: "patient")

        return user
    }

    // MARK: - Email/Password Signup
    func signup(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }

    // MARK: - Google Login Helper
    @MainActor
    func performGoogleSignIn() async throws -> (user: User, email: String) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(
                domain: "AuthService", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No Client ID found"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        else {
            throw NSError(
                domain: "AuthService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(
                domain: "AuthService", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No ID token found"])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString)

        let authResult = try await Auth.auth().signIn(with: credential)

        guard let email = authResult.user.email else {
            throw NSError(
                domain: "AuthService", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No email found in auth result"])
        }

        return (authResult.user, email)
    }

    // MARK: - Google Login (Patient)
    @MainActor
    func signInWithGoogle() async throws -> patientModel {
        let (_, email) = try await performGoogleSignIn()
        let userModel = try await fetchUser(email: email)

        // Save to Keychain
        if let id = userModel.id {
            try? KeychainManager.shared.save(key: .documentID, value: id)
            // For regular patient login, user ID IS the patient document ID
            try? KeychainManager.shared.save(key: .patientDocumentID, value: id)
        }
        if !userModel.patientUID.isEmpty {
            try? KeychainManager.shared.save(key: .patientUID, value: userModel.patientUID)
        }

        try? KeychainManager.shared.save(key: .userType, value: "patient")

        return userModel
    }

    // MARK: - Fetch User Data
    func fetchUser(email: String) async throws -> patientModel {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw NSError(
                domain: "AuthService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile not found for email: \(email)"])
        }

        var user = try document.data(as: patientModel.self)
        user.id = document.documentID
        print("Fetched User Details: \(user)")
        return user
    }

    // MARK: - Apple Sign-In Helpers
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Apple Sign-In (Patient)
    @MainActor
    func signInWithApple(
        idTokenString: String,
        nonce: String,
        appleEmail: String? = nil,
        fullName: PersonNameComponents? = nil
    ) async throws -> patientModel {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: fullName
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        let email = try resolveAppleEmail(for: authResult.user, appleEmail: appleEmail)

        let userModel = try await fetchUser(email: email)

        if let id = userModel.id {
            try? KeychainManager.shared.save(key: .documentID, value: id)
            try? KeychainManager.shared.save(key: .patientDocumentID, value: id)
        }
        if !userModel.patientUID.isEmpty {
            try? KeychainManager.shared.save(key: .patientUID, value: userModel.patientUID)
        }
        try? KeychainManager.shared.save(key: .userType, value: "patient")

        return userModel
    }

    // MARK: - Apple Sign-In (Generic - returns user and email)
    @MainActor
    func performAppleSignIn(
        idTokenString: String,
        nonce: String,
        appleEmail: String? = nil,
        fullName: PersonNameComponents? = nil
    ) async throws -> AppleAuthResult {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: fullName
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        let email = try resolveAppleEmail(for: authResult.user, appleEmail: appleEmail)
        let resolvedName = resolveAppleName(from: fullName, fallback: authResult.user.displayName)

        return AppleAuthResult(
            user: authResult.user,
            email: email,
            firstName: resolvedName.firstName,
            lastName: resolvedName.lastName
        )
    }

    func getCurrentNonce() -> String? {
        return currentNonce
    }

    private func resolveAppleEmail(for user: User, appleEmail: String?) throws -> String {
        if let email = appleEmail?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            return email
        }

        if let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            return email
        }

        throw NSError(
            domain: "AuthService", code: 3,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "We couldn't read your Apple email address. Please try Sign in with Apple again."
            ])
    }

    private func resolveAppleName(
        from fullName: PersonNameComponents?,
        fallback displayName: String?
    ) -> (firstName: String, lastName: String) {
        let givenName = fullName?.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let familyName = fullName?.familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !givenName.isEmpty || !familyName.isEmpty {
            return (givenName, familyName)
        }

        let fallbackName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !fallbackName.isEmpty else {
            return ("", "")
        }

        let components = fallbackName.split(separator: " ").map(String.init)
        guard let firstName = components.first else {
            return ("", "")
        }

        let lastName = components.dropFirst().joined(separator: " ")
        return (firstName, lastName)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        try? KeychainManager.shared.delete(key: .documentID)
        try? KeychainManager.shared.delete(key: .patientUID)
        try? KeychainManager.shared.delete(key: .familyDocumentID)
        try? KeychainManager.shared.delete(key: .userType)
        try? KeychainManager.shared.delete(key: .patientDocumentID)
    }

    // MARK: - Forgot Password
    func sendPasswordReset(email: String) async throws {
        let _: ForgotPasswordResponse = try await NetworkManager.shared.request(
            endpoint: AuthEndpoint.forgotPassword(email: email)
        )
    }

    // MARK: - Delete Account
    func deleteAccount(documentId: String) async throws {
        print("Deleting account for documentId: \(documentId)")
        let _: DeleteAccountResponse = try await NetworkManager.shared.request(
            endpoint: AuthEndpoint.deleteAccount(documentId: documentId)
        )
        try signOut()
    }
}
