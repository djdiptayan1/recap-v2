//
//  patientTabbar.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct patientTabbar: View {
    var body: some View {
        TabView{
            Tab("Home", systemImage: "house.fill") {
                home()
            }
            Tab("Family", systemImage: "person.2.fill") {
                familyView()
            }
            Tab("Games", systemImage: "gamecontroller.fill") {
                games()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppConfig.Colors.accent)
        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
    }
}

#Preview {
    patientTabbar()
}
