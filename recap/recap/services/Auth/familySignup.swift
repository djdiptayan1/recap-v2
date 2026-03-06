//
//  familySignup.swift
//  recap
//
//  Created by Diptayan Jash on 01/01/26.
//

import Foundation

class FamilySignupService {
    static let shared = FamilySignupService()

    private init() {}

    // MARK: - API Endpoints
    private enum FamilySignupAPI: Endpoint {
        case createProfile(request: FamilySignupRequest)

        var path: String {
            switch self {
            case .createProfile:
                return AppConfig.ApiEndpoints.familySignupCompletion
            }
        }

        var method: HTTPMethod {
            switch self {
            case .createProfile:
                return .post
            }
        }

        var body: Encodable? {
            switch self {
            case .createProfile(let request):
                return request
            }
        }
    }

    // MARK: - Create Family Profile (Backend API)
    func createFamilyProfile(request: FamilySignupRequest) async throws -> FamilySignupResponse {
        return try await NetworkManager.shared.request(
            endpoint: FamilySignupAPI.createProfile(request: request))
    }
}

// MARK: - DTOs
struct FamilySignupRequest: Codable {
    let patient_documentId: String
    let email: String
    let name: String
    let profileImageBase64: String
    let profileImageURL: String?
    let phone: String
    let relation: String
}

// Response matching backend: { "success": true, "message": "...", "data": { ... } }
// Response matching backend: { "success": true, "message": "...", "data": { ... } }
struct FamilySignupResponse: Codable {
    let success: Bool
    let message: String
    let data: FamilySignupResponseData?
}

struct FamilySignupResponseData: Codable {
    let id: String
    let name: String
    let email: String
    let imageURL: String?
    let phone: String?
    let relation: String?
}
