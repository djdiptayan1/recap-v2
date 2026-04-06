//
//  AnalyticsManager.swift
//  recap
//

import FirebaseAnalytics
import Foundation

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    /// Log a screen view event
    /// - Parameters:
    ///   - screenName: The name of the screen being viewed
    ///   - screenClass: The class name of the view (optional)
    func logScreen(name screenName: String, class screenClass: String? = nil) {
        var params: [String: Any] = [
            AnalyticsParameterScreenName: screenName
        ]
        
        if let screenClass = screenClass {
            params[AnalyticsParameterScreenClass] = screenClass
        }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
        print("📊 [Analytics] Screen: \(screenName)")
    }
    
    /// Log a custom event with optional parameters
    /// - Parameters:
    ///   - event: The name of the event
    ///   - parameters: A dictionary of key-value pairs to log with the event
    func logEvent(name event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
        print("📊 [Analytics] Event: \(event), Params: \(parameters ?? [:])")
    }
    
    /// Set a user property for analytics
    /// - Parameters:
    ///   - value: The value of the property
    ///   - name: The name of the property
    func setUserProperty(value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    /// Log a login event
    /// - Parameter method: The login method (e.g., "email", "google")
    func logLogin(method: String) {
        logEvent(name: AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    /// Log a sign-up event
    /// - Parameter method: The sign-up method (e.g., "email", "google")
    func logSignUp(method: String) {
        logEvent(name: AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
}

// MARK: - Event Constants
extension AnalyticsManager {
    enum Events {
        static let gameStart = "game_start"
        static let gameComplete = "game_complete"
        static let dailyQuestionAnswered = "daily_question_answered"
        static let journalCreated = "journal_created"
        static let reminderSet = "reminder_set"
        static let reportExported = "report_exported"
    }
    
    enum Parameters {
        static let gameType = "game_type"
        static let score = "score"
        static let patientId = "patient_id"
        static let duration = "duration"
    }
}
