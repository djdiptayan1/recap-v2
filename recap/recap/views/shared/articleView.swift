//
//  articleView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct ArticlesView: View {
    
    @StateObject private var viewModel = ArticlesViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleCard(article: article)
                        }
                        .buttonStyle(PlainButtonStyle()) // Removes blue link color
                    }
                }
                .padding(AppConfig.UI.screenPadding - 10)
                .padding(.top, 10)
            }
        }
        .standardBackground()
        .navigationTitle("Articles")
        .task {
            await viewModel.fetchArticles()
        }
    }
}

#Preview {
    ArticlesView()
}
