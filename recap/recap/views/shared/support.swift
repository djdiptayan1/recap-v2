//
//  support.swift
//  recap
//
//  Created by Diptayan Jash on 11/12/25.
//

import SwiftUI
import WebKit

struct support: View {
    @State private var page = WebPage()
    private let urlString = "https://recap.djdiptayan.in/support"
    
    var body: some View {
        // NavigationStack {
            ZStack {
                WebView(page)
                    .accessibilityLabel("Support page")
                    .ignoresSafeArea(.all)
                if page.isLoading {
                    ProgressView(value: page.estimatedProgress)
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .accessibilityLabel("Loading support page")
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let url = URL(string: urlString) {
                    page.load(URLRequest(url: url))
                } else {
                    print("Error: Invalid URL")
                }
            }
        // }
    }
}

#Preview {
    support()
}
