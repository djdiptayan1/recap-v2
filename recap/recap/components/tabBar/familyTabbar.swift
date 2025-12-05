//
//  familyTabbar.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import SwiftUI

struct familyTabbar: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                home_family()
            }
            Tab("Articles", systemImage: "person.2.fill") {
                NavigationStack {
                    ArticlesView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppConfig.Colors.accent)
        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
    }
}

#Preview {
    familyTabbar()
}
