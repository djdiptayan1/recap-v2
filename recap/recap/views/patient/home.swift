//
//  home.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct home: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var familyViewModel = FamilyViewModel(documentID: "")
    @State private var showProfile = false
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 24) {
                    QuestionsCard(hasFamilyMembers: !familyViewModel.familyMembers.isEmpty)
                    StreaksCard()
                    LetsReadCard()
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
                    ProfileView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                if let uid = appState.currentUser?.id {
                     familyViewModel.updateDocumentID(uid)
                     Task {
                        await familyViewModel.fetchFamilyMembers()
                     }
                }
            }
        }
    }
}

#Preview {
    home()
}
