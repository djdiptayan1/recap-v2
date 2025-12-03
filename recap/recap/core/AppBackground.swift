//
//  AppBackground.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct AppBackground: View {
    private let colorTeal = Color(red: 0.69, green: 0.88, blue: 0.88)
    private let colorPink = Color(red: 0.94, green: 0.74, blue: 0.80)
    
//    private let colorTeal = AppConfig.Colors.accent
//    private let colorPink = AppConfig.Colors.alert
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            GeometryReader { proxy in
                ZStack {
                    // Teal Orb (Top Left)
                    Circle()
                        .fill(colorTeal)
                        .frame(width: proxy.size.width * 1.2)
                        .offset(x: -proxy.size.width * 0.3, y: -proxy.size.height * 0.3)
                        .blur(radius: 80) // High blur creates the mesh look
                    
                    // Pink Orb (Bottom Right)
                    Circle()
                        .fill(colorPink)
                        .frame(width: proxy.size.width * 1.2)
                        .offset(x: proxy.size.width * 0.3, y: proxy.size.height * 0.4)
                        .blur(radius: 80)
                    
                    // Optional: A middle blending orb to smooth the transition
                    Circle()
                        .fill(colorTeal.opacity(0.5))
                        .frame(width: proxy.size.width * 0.8)
                        .offset(y: proxy.size.height * 0.1)
                        .blur(radius: 100)
                }
            }
            .ignoresSafeArea()
            
            // 3. Glass Texture Overlay
            Color.white.opacity(0.3)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    AppBackground()
}
