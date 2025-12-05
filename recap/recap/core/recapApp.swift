//
//  recapApp.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct recapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                if appState.currentUser?.type == "patient" {
                    patientTabbar()
                        .environmentObject(appState)
                } else {
                    familyTabbar()
                        .environmentObject(appState)
                }
            } else {
                welcomeView()
                    .environmentObject(appState)
            }
        }
    }
}
