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

    @State private var memberToDelete: FamilyMember? = nil
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteConfirmation = false

    var body: some View {
        let documentID = appState.currentUser?.id ?? ""

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
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
                                    .onLongPressGesture {
                                        HapticManager.shared.trigger(.warning)
                                        memberToDelete = member
                                        showDeleteConfirmation = true
                                    }
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
            // Step 1: Initial confirmation
            .alert(
                "Remove Family Member?", isPresented: $showDeleteConfirmation,
                presenting: memberToDelete
            ) { member in
                Button("Cancel", role: .cancel) {
                    memberToDelete = nil
                }
                Button("Remove", role: .destructive) {
                    showFinalDeleteConfirmation = true
                }
            } message: { member in
                Text("Are you sure you want to remove \(member.name) from your family?")
            }
            // Step 2: Final confirmation
            .alert(
                "Are you absolutely sure?", isPresented: $showFinalDeleteConfirmation,
                presenting: memberToDelete
            ) { member in
                Button("Cancel", role: .cancel) {
                    memberToDelete = nil
                }
                Button("Yes, Remove", role: .destructive) {
                    Task {
                        await viewModel.deleteFamilyMember(memberID: member.id)
                        memberToDelete = nil
                    }
                }
            } message: { member in
                Text(
                    "This will permanently remove \(member.name) from your family. This action cannot be undone."
                )
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
