//
//  patientSignup.swift
//  recap
//
//  Created by Diptayan Jash on 08/12/25.
//

import Foundation

class PatientSignupService {
    static let shared = PatientSignupService()

    private init() {}

    // MARK: - API Endpoints
    private enum PatientSignupAPI: Endpoint {
        case createProfile(request: PatientSignupRequest)

        var path: String {
            switch self {
            case .createProfile:
                return AppConfig.ApiEndpoints.patientSignupCompletion
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

    // MARK: - Create Patient Profile (Backend API)
    func createPatientProfile(request: PatientSignupRequest) async throws {
        // We expect a successful response, even if empty/generic
        let _: PatientSignupResponse = try await NetworkManager.shared.request(
            endpoint: PatientSignupAPI.createProfile(request: request))
    }
}

// MARK: - DTOs
struct PatientSignupRequest: Codable {
    let uid: String
    let email: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let bloodGroup: String
    let sex: String
    let stage: String
    let profileImageBase64: String
    let profileImageURL: String?
}

// Response matching backend: { "message": "...", "user": { ... } }
struct PatientSignupResponse: Codable {
    let message: String
    let user: patientModel?
}
