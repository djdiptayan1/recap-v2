//
//  SmritiIdentityResolver.swift
//  recap
//

import Foundation

struct ResolvedIdentity {
    let actorDocumentId: String
    let patientDocumentId: String?
    let familyDocumentId: String?
    let userType: String
}

enum IdentityResolutionError: Error {
    case missingActorId
    case missingPatientId
}

@MainActor
final class SmritiIdentityResolver {
    static let shared = SmritiIdentityResolver()
    private init() {}

    func resolve(fallbackPatientId: String?) throws -> ResolvedIdentity {
        let userType = KeychainManager.shared.getString(key: .userType) ?? "patient"
        let actorDocumentId =
            KeychainManager.shared.getString(key: .documentID)
            ?? fallbackPatientId

        guard let actorDocumentId, !actorDocumentId.isEmpty else {
            throw IdentityResolutionError.missingActorId
        }

        let keychainPatientId = KeychainManager.shared.getString(key: .patientDocumentID)
        let keychainFamilyId = KeychainManager.shared.getString(key: .familyDocumentID)

        let patientDocumentId: String?
        if let keychainPatientId, !keychainPatientId.isEmpty {
            patientDocumentId = keychainPatientId
        } else if userType == "patient" {
            patientDocumentId = actorDocumentId
        } else {
            patientDocumentId = fallbackPatientId
        }

        if patientDocumentId == nil || patientDocumentId?.isEmpty == true {
            throw IdentityResolutionError.missingPatientId
        }

        let familyDocumentId: String?
        if let keychainFamilyId, !keychainFamilyId.isEmpty {
            familyDocumentId = keychainFamilyId
        } else if userType == "family" {
            familyDocumentId = actorDocumentId
        } else {
            familyDocumentId = nil
        }

        return ResolvedIdentity(
            actorDocumentId: actorDocumentId,
            patientDocumentId: patientDocumentId,
            familyDocumentId: familyDocumentId,
            userType: userType
        )
    }
}
