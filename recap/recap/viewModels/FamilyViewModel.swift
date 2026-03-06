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
        case delete(documentID: String, memberID: String)
        
        var path: String {
            switch self {
            case .fetch(let documentID):
                return AppConfig.ApiEndpoints.familyMembers + "/\(documentID)"
            case .delete(let documentID, let memberID):
                return AppConfig.ApiEndpoints.familyMembers + "/\(documentID)/\(memberID)"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .fetch: return .get
            case .delete: return .delete
            }
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
    // MARK: - Fetch Methods
    
    @MainActor
    func fetchFamilyMembers() async {
        guard !documentID.isEmpty else { return }
        guard familyMembers.isEmpty else { return }

        // Use prefetched data if available
        if let cached = DataPrefetchManager.shared.familyMembers {
            self.familyMembers = cached
            return
        }

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
    
    @MainActor
    func deleteFamilyMember(memberID: String) async -> Bool {
        guard !documentID.isEmpty else { return false }
        errorMessage = nil
        
        struct DeleteResponse: Decodable {
            let success: Bool
            let message: String?
        }
        
        do {
            let response: DeleteResponse = try await NetworkManager.shared.request(endpoint: FamilyAPI.delete(documentID: documentID, memberID: memberID))
            if response.success {
                familyMembers.removeAll { $0.id == memberID }
                return true
            } else {
                errorMessage = response.message ?? "Failed to delete family member"
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting family member: \(error)")
        }
        
        return false
    }
}
