//
//  AppState.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: patientModel? {
        didSet {
            isLoggedIn = currentUser != nil
        }
    }

    @MainActor
    func restoreSession() async {
        guard let firebaseUser = Auth.auth().currentUser,
            let email = firebaseUser.email
        else {
            return
        }

        let userType = KeychainManager.shared.getString(key: .userType)

        do {
            if userType == "family" {
                if let patientDocId = KeychainManager.shared.getString(key: .patientDocumentID) {
                    let response = try await FamilyAuthService.shared.verifyFamilyMember(
                        email: email, documentId: patientDocId)

                    if response.success {
                        let patientUID =
                            response.patientdata?.patientUID ?? KeychainManager.shared.getString(
                                key: .patientUID) ?? ""

                        var familyUser = patientModel(
                            firstName: response.name ?? "Family Member",
                            lastName: "",
                            patientUID: patientUID,
                            dateOfBirth: "",
                            sex: "",
                            bloodGroup: "",
                            stage: "",
                            profileImageURL: CloudinaryUtility.optimize(response.imageURL, transform: .avatar),
                            email: email,
                            id: response.familymember_documentId,
                            type: "family",
                            familyMembers: []
                        )
                        familyUser.relation = response.relation
                        familyUser.phone = response.phone
                        familyUser.linkedPatient = response.patientdata

                        self.currentUser = familyUser
                    } else {
                        try? AuthService.shared.signOut()
                    }
                }
            } else {
                let user = try await AuthService.shared.fetchUser(email: email)
                self.currentUser = user
            }
        } catch {
            print("Error restoring session: \(error)")
        }
    }
}
