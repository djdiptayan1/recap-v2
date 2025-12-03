//
//  MemorizePhaseView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI
struct MemorizePhaseView: View {
    let objects: [DailyObject]
    let timeProgress: CGFloat
    let timeString: String
    let onReady: () -> Void
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Instruction
            VStack(spacing: 10) {
                Text("Memorize these items")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                
                // Gentle Progress Bar
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppConfig.Colors.accent)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppConfig.Colors.stroke)
                            Capsule()
                                .fill(AppConfig.Colors.accent)
                                .frame(width: geo.size.width * timeProgress)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(timeString)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(AppConfig.Colors.accent)
                }
                .frame(maxWidth: 250)
            }
            .padding(.top, 20)
            
            // The Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(objects) { object in
                        GameObjectCard(object: object, isSelected: false)
                    }
                }
                .padding()
            }
            
            // "I'm Ready" Button (Allows user to control pace)
            Button(action: onReady) {
                Text("I'm Ready")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppConfig.Colors.accent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}
