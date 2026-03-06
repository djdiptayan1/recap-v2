//
//  familyCard.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//
import SwiftUI

struct FamilyCard: View {
    let member: FamilyMember

    // Color logic
    private var relationshipColor: Color {
        switch member.relation.lowercased() {
        case "son", "brother", "father", "husband": return Color.blue
        case "daughter", "sister", "mother", "wife": return Color.pink
        default: return AppConfig.Colors.accent
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // 1. Full Image
            GeometryReader { geo in
                AsyncImage(url: URL(string: member.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        // Fallback
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            // 2. Gradient Overlay (Improved visibility)
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.0)],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 120)
            .accessibilityHidden(true)

            // 3. Info Layer
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    // Relationship Badge (Horizontal Pill)
                    Text(member.relation.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(relationshipColor)
                        .clipShape(Capsule())
                        .shadow(radius: 2)

                    // Name (Scaled to fit)
                    Text(member.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)  // Prevents truncation like "Bo..."
                        .shadow(radius: 2)
                }

                Spacer(minLength: 8)

                // Call Button
                Button(action: {
                    if let url = URL(string: "tel://\(member.phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "phone.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Call \(member.name)")
                .accessibilityHint("Makes a phone call to \(member.name).")
                .accessibilityAddTraits(.isButton)
            }
            .padding(16)
        }
        .frame(height: 220)  // Reduced height slightly to balance the width
        //        .background(Color.white)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(AppConfig.UI.cornerRadius)
        // Soft Shadow to lift card off background
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        // Grey background to see the card clearly
        Color.gray.opacity(0.2).ignoresSafeArea()

        let familyMember = FamilyMember(
            id: UUID().uuidString,
            name: "Jack Puth",
            relation: "Husband",
            phone: "8208457322",
            email: "contact@example.com",
            imageURL:
                "https://as1.ftcdn.net/v2/jpg/02/99/04/20/1000_F_299042079_vGBD7wIlSeNl7vOevWHiL93G4koMM967.jpg"
        )

        FamilyCard(member: familyMember)
            .padding()
    }
}
