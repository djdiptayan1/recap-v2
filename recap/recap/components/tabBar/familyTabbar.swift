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
            Tab("Smriti", systemImage: "apple.intelligence") {
                SmritiView()
            }
            Tab("Reminders", systemImage: "bell.badge.waveform.fill") {
                NavigationStack {
                    remindersView()
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
