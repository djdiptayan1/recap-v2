//
//  AuthService.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()

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

    func signOut() throws {
        try Auth.auth().signOut()
        try? KeychainManager.shared.delete(key: .documentID)
        try? KeychainManager.shared.delete(key: .patientUID)
        try? KeychainManager.shared.delete(key: .familyDocumentID)
        try? KeychainManager.shared.delete(key: .userType)
        try? KeychainManager.shared.delete(key: .patientDocumentID)
    }
}
