import SDWebImageSwiftUI
//
//  ArticleDetailView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//
//
import SafariServices
import SwiftUI

struct ArticleDetailView: View {
    let article: articleModel
    @Environment(\.dismiss) var dismiss
    @State private var showSafari = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                GeometryReader { geometry in
                    WebImage(url: URL(string: article.image))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 300)
                        .clipped()
                }
                .frame(height: 300)
                VStack(alignment: .leading, spacing: 20) {
                    // Title Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text("Source: \(article.source)")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    .padding(.bottom, 10)

                    Divider()

                    // Main Text - High Readability
                    Text(article.content)
                        .font(.system(size: 19, weight: .regular, design: .serif))  // Serif + Large size
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineSpacing(8)  // Extra breathing room

                    // Citation Box
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

                    // Action Button
                    Button(action: { showSafari = true }) {
                        HStack {
                            Text("Read Original Article")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.up.right")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppConfig.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppConfig.UI.cornerRadius)
                        .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                }
                .padding(AppConfig.UI.screenPadding - 10)
                .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                .offset(y: -40)  // Overlap effect
            }
        }
        .edgesIgnoringSafeArea(.top)
        // .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            if let url = URL(string: article.link) {
                SafariView(url: url)
            }
        }
    }
}

// Simple Safari Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    let mockArticle = articleModel(
        id: "1",
        title: "Caregiver Guide: Managing Stress",
        author: "Sarah-Louise Kelly",
        content:
            "I would tell you that life matters most when you lead with kindness, stay curious, and choose courage over comfort, lessons shaped by my earliest memories of sitting beneath a big oak tree listening to my grandmother’s stories. I was born in a small, warm town where everyone knew each other, and growing up there felt like living inside a friendly, slow-moving river. My childhood was simple and sweet—long summer days, scraped knees, and the thrill of discovering little wonders—and in school I loved anything that let me create, especially writing and music. As a child, I spent most of my time drawing, building things, and collecting odd treasures like marbles and bottle caps, small pieces of the world that felt magical. Something most people don’t know about me is that I’m surprisingly sentimental; I keep memories the way others keep photographs. My favorite music artist was always someone whose lyrics felt like truth—artists who could turn emotion into sound, because they reminded me that honesty is its own kind of art. The most interesting job I ever had was working in a community center, where I met people whose stories opened my eyes to lives different from mine. I’ve loved deeply once, and it grew slowly—a friendship that softened into something more—teaching me that real love feels like being fully seen. The historical moment that affected me most was witnessing how connected the world became through technology; it changed everything about how we communicate, learn, and understand one another. My favorite decade was the one where I finally understood myself, not because of the world around me but because of the confidence I grew within it. My role models were quiet but strong people—teachers, family, mentors—who showed me how powerful patience and integrity can be. The most interesting place I ever traveled to was a coastal town where the ocean seemed to erase all noise except the rhythm of the waves. A challenge I overcame was learning to let go of perfection; it taught me to embrace progress and compassion for myself. My proudest accomplishment has been becoming someone I would have admired as a child. If I could speak to my younger self, I would say: “Don’t rush. Everything blooms when it’s ready.” The best book I’ve read was one that made me feel understood—stories that mirrored my own uncertainties and offered clarity. The biggest change I’ve witnessed is how people now share their lives so publicly, for better or worse, reshaping relationships and identity. The funniest moment in my life was when a supposedly serious speech I gave was interrupted by a runaway balloon that hit me in the face, breaking the tension and making everyone—including me—burst into laughter. As for the future, I hope for more empathy in the world, more listening than speaking, and I hope to be remembered simply as someone who tried to make life a little better for others.",
        image: "https://picsum.photos/id/29/1000/1000",
        thumbnailImage: nil,
        link:
            "https://www.huffingtonpost.co.uk/entry/21-questions-you-should-ask-people-with-dementia-to-bridge-the-conversation-gap_uk_64639d3fe4b0c10612ee68df",
        source:
            "https://www.huffingtonpost.co.uk/entry/21-questions-you-should-ask-people-with-dementia-to-bridge-the-conversation-gap_uk_64639d3fe4b0c10612ee68df",
        citation: "medicalnewstoday"
    )
    ArticleDetailView(article: mockArticle)
}
