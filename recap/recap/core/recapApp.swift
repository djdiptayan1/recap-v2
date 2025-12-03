//
//  recapApp.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

@main
struct recapApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                patientTabbar()
                    .environmentObject(appState)
            } else {
                welcomeView()
                    .environmentObject(appState)
            }
        }
    }
}
