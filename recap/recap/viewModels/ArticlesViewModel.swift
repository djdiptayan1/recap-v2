//
//  ArticlesViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ArticlesViewModel: ObservableObject {
    @Published var articles: [articleModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchArticles() async {
        guard articles.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let response: ArticleResponse = try await NetworkManager.shared.request(endpoint: ArticlesAPI.getArticles)
            if response.success {
                self.articles = response.data
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

private enum ArticlesAPI: Endpoint {
    case getArticles
    
    var path: String {
        switch self {
        case .getArticles:
            return AppConfig.ApiEndpoints.articles
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getArticles:
            return .get
        }
    }
}
