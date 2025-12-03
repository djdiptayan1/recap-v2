//
//  family.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

// Example data for family members (with valid IDs)
var familyMembers = [
    FamilyMember(
        id: UUID().uuidString, // Generate a unique ID for each family member
        name: "Bobby Deol",
        relationship: "Brother",
        phone: "8208457322",
        email: "contact@djdiptayan.in",
        password: "password",
        imageName: "familyImg",
        imageURL: "https://as1.ftcdn.net/v2/jpg/02/99/04/20/1000_F_299042079_vGBD7wIlSeNl7vOevWHiL93G4koMM967.jpg"
    ),
    FamilyMember(
        id: UUID().uuidString,
        name: "Charlie Puth",
        relationship: "Son",
        phone: "8208457322",
        email: "contact@djdiptayan.in",
        password: "password",
        imageName: "familyImg",
        imageURL: "https://as1.ftcdn.net/v2/jpg/02/99/04/20/1000_F_299042079_vGBD7wIlSeNl7vOevWHiL93G4koMM967.jpg"
    ),
    FamilyMember(
        id: UUID().uuidString,
        name: "Jack Puth",
        relationship: "Wife",
        phone: "8208457322",
        email: "contact@djdiptayan.in",
        password: "password",
        imageName: "familyImg",
        imageURL: "https://as1.ftcdn.net/v2/jpg/02/99/04/20/1000_F_299042079_vGBD7wIlSeNl7vOevWHiL93G4koMM967.jpg"
    ),
]

struct familyView: View {
    // Increased spacing for a cleaner, less cramped look
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // 2. The Grid
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(familyMembers) { member in
                            FamilyCard(member: member)
                        }
                    }

                    // Bottom padding for scrolling
                    Spacer().frame(height: 40)
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("My Family")
        }
    }
}

#Preview {
    familyView()
}
