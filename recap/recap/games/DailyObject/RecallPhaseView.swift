//
//  RecallPhaseView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct RecallPhaseView: View {
    let allObjects: [DailyObject]
    let selectedIDs: Set<UUID>
    let onToggle: (DailyObject) -> Void
    let onSubmit: () -> Void
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Which items did you see?")
                .font(AppConfig.Fonts.titleMedium)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .padding(.top, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(allObjects) { object in
                        GameObjectCard(
                            object: object,
                            isSelected: selectedIDs.contains(object.id)
                        )
                        .onTapGesture {
                            onToggle(object)
                        }
                        // Scale animation on tap
                        .scaleEffect(selectedIDs.contains(object.id) ? 0.95 : 1.0)
                        .animation(.spring(), value: selectedIDs.contains(object.id))
                    }
                }
                .padding()
            }
            
            Button(action: onSubmit) {
                Text("Submit Answers")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedIDs.isEmpty ? Color.gray : AppConfig.Colors.accent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .disabled(selectedIDs.isEmpty)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}
