//
//  family.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct familyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FamilyViewModel(documentID: "")

    // Increased spacing for a cleaner, less cramped look
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        let documentID = appState.currentUser?.id ?? ""

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else if viewModel.familyMembers.isEmpty {
                        Text("No family members found.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else {
                        // 2. The Grid
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.familyMembers) { member in
                                FamilyCard(member: member)
                            }
                        }

                        // Bottom padding for scrolling
                        Spacer().frame(height: 40)
                    }
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("My Family")
            .onAppear {
                if !documentID.isEmpty {
                    viewModel.updateDocumentID(documentID)
                    Task {
                        await viewModel.fetchFamilyMembers()
                    }
                }
            }
            .onChange(of: documentID) { newID in
                if !newID.isEmpty {
                    viewModel.updateDocumentID(newID)
                    Task {
                        await viewModel.fetchFamilyMembers()
                    }
                }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    appState.currentUser = patientModel(
        firstName: "Preview",
        lastName: "User",
        id: "NxCgHvgB2AXtvaxxfhw9OCqZIKy1"
    )
    return familyView()
        .environmentObject(appState)
}
