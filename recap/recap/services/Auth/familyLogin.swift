//
//  familyLogin.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Foundation

enum AuthEndpoint: Endpoint {
    case verifyUID(uid: String)
    case verifyFamilyMember(email: String, documentId: String)
    case createFamilyUser(uid: String, email: String, name: String, photoURL: String?)
    case forgotPassword(email: String)
    case deleteAccount(uid: String)
    
    var path: String {
        switch self {
        case .verifyUID:
            return AppConfig.ApiEndpoints.verifyUID
        case .verifyFamilyMember:
            return AppConfig.ApiEndpoints.verifyFamilyMember
        case .createFamilyUser:
            return AppConfig.ApiEndpoints.createFamilyUser
        case .forgotPassword:
            return AppConfig.ApiEndpoints.forgotPassword
        case .deleteAccount:
            return AppConfig.ApiEndpoints.deleteAccount
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .verifyUID, .verifyFamilyMember, .createFamilyUser, .forgotPassword, .deleteAccount:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .verifyUID(let uid):
            return ["patientUID": uid]
        case .verifyFamilyMember(let email, let documentId):
            return [
                "email": email,
                "documentId": documentId
            ]
        case .createFamilyUser(let uid, let email, let name, let photoURL):
            return [
                "patientUID": uid,
                "email": email,
                "name": name,
                "photoURL": photoURL
            ]
        case .forgotPassword(let email):
            return ["email": email]
        case .deleteAccount(let uid):
            return ["uid": uid]
        }
    }
}

struct VerifyUIDResponse: Codable {
    let success: Bool
    let exists: Bool
    let message: String
    let documentId: String?
    let patientUID: String?
}

struct VerifyFamilyMemberResponse: Codable {
    let success: Bool
    let familymember_documentId: String?
    let name: String?
    let imageURL: String?
    let email: String?
    let phone: String?
    let relation: String?
    let message: String
    let patientdata: LinkedPatientModel?
}

struct CreateFamilyUserResponse: Codable {
    let success: Bool
    let message: String
    let user: patientModel?
}

struct ForgotPasswordResponse: Codable {
    let success: Bool
    let message: String
}

struct DeleteAccountResponse: Codable {
    let success: Bool
    let message: String
}

class FamilyAuthService {
    static let shared = FamilyAuthService()
    private init() {}
    
    func verifyPatientUID(_ uid: String) async throws -> VerifyUIDResponse {
        return try await NetworkManager.shared.request(endpoint: AuthEndpoint.verifyUID(uid: uid))
    }
    
    func verifyFamilyMember(email: String, documentId: String) async throws -> VerifyFamilyMemberResponse {
        return try await NetworkManager.shared.request(endpoint: AuthEndpoint.verifyFamilyMember(email: email, documentId: documentId))
    }
    
    func createFamilyUser(patientUID: String, email: String, name: String, photoURL: String?) async throws -> patientModel {
        let response: CreateFamilyUserResponse = try await NetworkManager.shared.request(
            endpoint: AuthEndpoint.createFamilyUser(uid: patientUID, email: email, name: name, photoURL: photoURL)
        )
        guard let user = response.user else {
            throw NetworkError.unknown(NSError(domain: "FamilyAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"]))
        }
        return user
    }
}
