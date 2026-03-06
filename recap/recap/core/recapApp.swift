//
//  recapApp.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        NotificationManager.shared.registerReminderCategories()
        return true
    }
}

@main
struct recapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    SplashScreenView()
                        .environmentObject(appState)
                } else if appState.isLoggedIn {
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
}
