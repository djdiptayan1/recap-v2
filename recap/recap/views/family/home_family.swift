//
//  home_family.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//
import SwiftUI

struct home_family: View {
    @State private var showProfile = false
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 24) {
                    QuestionsCard()
//                    StreaksCard()
//                    LetsReadCard()
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile.toggle()
                    }) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileFamilyView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    home_family()
}
