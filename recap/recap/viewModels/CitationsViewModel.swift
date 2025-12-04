//
//  CitationsViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CitationsViewModel: ObservableObject {
    @Published var citations: [citationModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchCitations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: CitationResponse = try await NetworkManager.shared.request(endpoint: CitationsAPI.getCitations)
            if response.success {
                self.citations = response.data
            } else {
                self.errorMessage = "Failed to fetch articles"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching articles: \(error)")
        }
        
        isLoading = false
    }
}

private enum CitationsAPI: Endpoint {
    case getCitations
    
    var path: String {
        switch self {
        case .getCitations:
            return AppConfig.ApiEndpoints.citations
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getCitations:
            return .get
        }
    }
}
