//
//  FamilyViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Foundation
import Combine

class FamilyViewModel: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var documentID: String
    
    init(documentID: String) {
        self.documentID = documentID
    }
    
    func updateDocumentID(_ id: String) {
        self.documentID = id
    }
    
    // MARK: - API Endpoints
    private enum FamilyAPI: Endpoint {
        case fetch(documentID: String)
        
        var path: String {
            switch self {
            case .fetch(let documentID):
                return AppConfig.ApiEndpoints.familyMembers + "/\(documentID)"
//                return "familymembers/\(documentID)"
            }
        }
        
        var method: HTTPMethod { .get }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
    // MARK: - Fetch Methods
    
    @MainActor
    func fetchFamilyMembers() async {
        guard !documentID.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let response: FamilyMemberResponse = try await NetworkManager.shared.request(endpoint: FamilyAPI.fetch(documentID: documentID))
            if response.success {
                self.familyMembers = response.data
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching family members: \(error)")
        }
        
        isLoading = false
    }
}
