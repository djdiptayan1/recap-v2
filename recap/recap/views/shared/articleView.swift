//
//  articleView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct ArticlesView: View {
    
    // MOCK DATA - Direct Injection for UI Testing
    let articles = [
        articleModel(
            title: "Understanding Early Signs of Alzheimer's",
            author: "Dr. Sarah Smith",
            content: "Alzheimer's disease is a progressive neurological disease that affects memory, thinking, and behavior. It is the most common cause of dementia, which involves a decline in cognitive function. People with Alzheimer's often experience memory loss, confusion, and changes in behavior. Over time, individuals with Alzheimer's require increasing assistance with daily tasks. In the early stages, a person may still be able to live independently, but as the disease progresses, they may need help with tasks like bathing, dressing, and managing medications.",
            image: "https://images.pexels.com/photos/30877714/pexels-photo-30877714.jpeg",
            link: "https://www.medicalnewstoday.com/articles/326374#summary",
            source: "Alzheimer's Association",
            citation: "2024 Alzheimer's Disease Facts and Figures."
        ),
        articleModel(
            title: "Caregiver Guide: Managing Stress",
            author: "Healthline Editorial",
            content: "Caregiving can be rewarding, but it can also be stressful. Ideally, caregiving should be a shared responsibility. But often, one person takes on the bulk of the work. It is important to recognize the signs of caregiver burnout and take steps to manage your own health.",
            image: "https://images.pexels.com/photos/30877714/pexels-photo-30877714.jpeg",
            link: "https://google.com",
            source: "Healthline",
            citation: ""
        ),
        articleModel(
            title: "The Best Foods for Brain Health",
            author: "Nutrition Daily",
            content: "What you eat plays a role in your brain health. The MIND diet, which is a hybrid of the Mediterranean and DASH diets, may help reduce the risk of Alzheimer's disease. Key foods include leafy greens, berries, nuts, and fish.",
            image: "https://images.pexels.com/photos/30877714/pexels-photo-30877714.jpeg",
            link: "https://google.com",
            source: "Nutrition Today",
            citation: "Journal of Nutrition, 2023"
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCard(article: article)
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes blue link color
                }
            }
            .padding(AppConfig.UI.screenPadding - 10)
            .padding(.top, 10)
        }
        .standardBackground()
        .navigationTitle("Articles")
    }
}

#Preview {
    ArticlesView()
}
