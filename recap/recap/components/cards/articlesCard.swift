//
//  articlesCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//
import SwiftUI
import SDWebImageSwiftUI

struct ArticleCard: View {
    let article: articleModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                WebImage(url: URL(string: article.image))
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                .frame(height: 180)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .bottom, endPoint: .center)
                )
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(article.readTime)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(AppConfig.UI.cornerRadius)
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(article.title)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Spacer()
                    
                    Text("By \(article.author)")
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
//        .overlay(
//            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
//                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
//        )
    }
}

#Preview {
    let mockArticle = articleModel(
        id: "String",
        title: "Latest Research on Alzheimer's and Memory Retention",
        author: "Dr. L. Chen",
        content: "Caregiving can be highly rewarding, but requires strategic management of the patient's routine and the caregiver's own health to avoid burnout. Remember to prioritize sleep and short breaks.",
        image: "https://picsum.photos/id/102/1000/600",
        link: "https://example.com",
        source: "The Journal of Aging",
        citation: "JN, 2024"
    )
    
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ArticleCard(article: mockArticle)
            .padding()
            .containerShape(Rectangle())
    }
}
