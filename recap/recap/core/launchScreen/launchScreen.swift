//
//  launchScreen.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI

struct launchScreen: View {
    @State private var isAnimating = false

    var body: some View {
        VStack {
            Image("recapLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
        }
        .standardBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    launchScreen()
}
