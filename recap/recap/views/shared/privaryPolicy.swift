//
//  privaryPolicy.swift
//  recap
//
//  Created by Diptayan Jash on 11/12/25.
//

import SwiftUI
import WebKit

struct privaryPolicy: View {
    @State private var page = WebPage()
    private let urlString = "https://recap.djdiptayan.in/privacyPolicy"

    var body: some View {
        // NavigationStack {
        ZStack {
            WebView(page)
                .ignoresSafeArea(.all)
            if page.isLoading {
                ProgressView(value: page.estimatedProgress)
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .background(Color(UIColor.systemBackground).opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Privacy Policy")
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
    privaryPolicy()
}
