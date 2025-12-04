//
//  AuthService.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Email/Password Login
    func signIn(email: String, password: String) async throws -> patientModel {
        let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = try await fetchUser(email: email)
        return user
    }
    
    // MARK: - Google Login
    @MainActor
    func signInWithGoogle() async throws -> patientModel {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Client ID found"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No ID token found"])
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        
        guard let email = authResult.user.email else {
             throw NSError(domain: "AuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No email found in auth result"])
        }
        
        let userModel = try await fetchUser(email: email)
        return userModel
    }
    
    // MARK: - Fetch User Data
    private func fetchUser(email: String) async throws -> patientModel {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found for email: \(email)"])
        }
        
        var user = try document.data(as: patientModel.self)
        user.id = document.documentID
        print("Fetched User Details: \(user)")
        return user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
