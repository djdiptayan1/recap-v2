//
//  SplashScreenView.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image("recapLogo")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.bottom, 10)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .standardBackground()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            checkLoginStatus()
        }
    }

    private func checkLoginStatus() {
        // Minimum display time for splash
        let minSplashTime = 2.0 // seconds
        let startTime = Date()

        Task {
            // Check session (this updates appState.currentUser and appState.isLoggedIn)
            await appState.restoreSession()

            // Prefetch all data during splash to reduce network calls on tab switches
            if appState.isLoggedIn, let user = appState.currentUser {
                let patientDocID =
                    KeychainManager.shared.getString(key: .patientDocumentID) ?? user.id ?? ""
                let documentID = user.id ?? ""
                await DataPrefetchManager.shared.prefetchAll(
                    documentID: documentID,
                    patientDocumentID: patientDocID
                )
            }

            // Calculate time elapsed
            let elapsed = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minSplashTime - elapsed)

            // Ensure minimum splash time
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1000000000))
            }

            // Update UI on main thread -> transition to next screen
            await MainActor.run {
                withAnimation {
                    appState.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
