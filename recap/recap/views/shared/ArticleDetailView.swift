//
//  ArticleDetailView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
import SafariServices
import SDWebImageSwiftUI

struct ArticleDetailView: View {
    let article: articleModel
    @Environment(\.dismiss) var dismiss
    @State private var showSafari = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    ZStack(alignment: .topLeading) {
                        WebImage(url: URL(string: article.image))
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(article.title)
                                .font(AppConfig.Fonts.headline)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                            
                            Text("Source: \(article.source)")
                                .font(AppConfig.Fonts.small)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                        .padding(.bottom, 10)
                        
                        Divider()
                        
                        Text(try! AttributedString(markdown: article.content))
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                            .lineSpacing(8)
                        
                        if !article.citation.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Medical Reference", systemImage: "staroflife.fill")
                                    .font(.caption)
                                    .foregroundColor(AppConfig.Colors.accent)
                                
                                Text(article.citation)
                                    .font(.caption)
                                    .italic()
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                            .padding()
                            .background(AppConfig.Colors.background)
                            .cornerRadius(12)
                            .padding(.top, 20)
                        }
                        
                        // Space for floating button
                        Spacer().frame(height: 100)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)
                    .offset(y: -40) // Overlap effect
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // --- Sticky Action Button ---
            VStack {
                Spacer()
                Button(action: { showSafari = true }) {
                    HStack {
                        Text("Read Original Article")
                            .fontWeight(.bold)
                            .font(.system(size: 16))
                        Image(systemName: "arrow.up.right")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppConfig.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(AppConfig.UI.cornerRadius)
                    .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        // .navigationBarHidden(true) // Removed to allow system back button
        .sheet(isPresented: $showSafari) {
            if let url = URL(string: article.link) {
                SafariView(url: url)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
