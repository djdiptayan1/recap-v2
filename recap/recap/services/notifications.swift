//
//  notifications.swift
//  recap
//
//  Created by Diptayan Jash on 18/01/26.
//

import Foundation
import UserNotifications
import UserNotificationsUI

/// A central manager for requesting notification authorization and scheduling local notifications.
/// Use `NotificationManager.shared` to access.
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    /// Calendar explicitly set to Indian Standard Time (IST)
    static var istCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let ist = TimeZone(identifier: "Asia/Kolkata") {
            calendar.timeZone = ist
        }
        return calendar
    }

    private let center = UNUserNotificationCenter.current()

    /// Set to true to log debug information
    var isDebugLoggingEnabled: Bool = true

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    /// Requests authorization to show alerts, play sounds, and badge the app icon.
    /// - Parameters:
    ///   - options: Authorization options. Defaults to alert, sound, and badge.
    ///   - completion: Called with a boolean indicating whether authorization was granted and an optional error.
    func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound, .badge],
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        center.requestAuthorization(options: options) { [weak self] granted, error in
            if self?.isDebugLoggingEnabled == true {
                print(
                    "[NotificationManager] Authorization granted: \(granted), error: \(String(describing: error))"
                )
            }
            DispatchQueue.main.async {
                completion?(granted, error)
            }
        }
    }

    /// Retrieves the current notification settings.
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings) }
        }
    }

    // MARK: - Categories & Actions

    /// Registers custom categories and actions for notifications.
    /// Call this early in app launch if you plan to use custom actions.
    func registerCategories(_ categories: Set<UNNotificationCategory>) {
        center.setNotificationCategories(categories)
        if isDebugLoggingEnabled {
            print(
                "[NotificationManager] Registered categories: \(categories.map { $0.identifier })")
        }
    }

    // MARK: - Scheduling

    /// Schedules a notification to be delivered immediately (after a short 1-second delay).
    @discardableResult
    func scheduleNow(
        title: String, body: String, categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:], sound: UNNotificationSound? = .default
    ) -> String {
        return schedule(
            after: 1, title: title, body: body, repeats: false,
            categoryIdentifier: categoryIdentifier, userInfo: userInfo, sound: sound)
    }

    /// Schedules a notification after a given number of seconds.
    @discardableResult
    func schedule(
        after seconds: TimeInterval, title: String, body: String, repeats: Bool = false,
        categoryIdentifier: String? = nil, userInfo: [AnyHashable: Any] = [:],
        sound: UNNotificationSound? = .default
    ) -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        if let categoryIdentifier { content.categoryIdentifier = categoryIdentifier }
        content.sound = sound

        let interval = repeats ? max(60, seconds) : max(1, seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            if let error {
                print("[NotificationManager] Failed to schedule (time interval): \(error)")
            } else if self?.isDebugLoggingEnabled == true {
                print(
                    "[NotificationManager] Scheduled (time interval) id=\(identifier) in \(interval)s repeats=\(repeats)"
                )
            }
        }
        return identifier
    }

    /// Schedules a notification at a specific date.
    @discardableResult
    func schedule(
        on date: Date, title: String, body: String, repeats: Bool = false,
        calendar: Calendar = .current, categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any] = [:], sound: UNNotificationSound? = .default
    ) -> String {
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        return schedule(
            on: components, title: title, body: body, repeats: repeats,
            categoryIdentifier: categoryIdentifier, userInfo: userInfo, sound: sound)
    }

    /// Schedules a notification using date components (e.g., every day at 9:00).
    @discardableResult
    func schedule(
        on components: DateComponents, title: String, body: String, repeats: Bool = false,
        categoryIdentifier: String? = nil, userInfo: [AnyHashable: Any] = [:],
        sound: UNNotificationSound? = .default
    ) -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        if let categoryIdentifier { content.categoryIdentifier = categoryIdentifier }
        content.sound = sound

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            if let error {
                print("[NotificationManager] Failed to schedule (calendar): \(error)")
            } else if self?.isDebugLoggingEnabled == true {
                print(
                    "[NotificationManager] Scheduled (calendar) id=\(identifier) components=\(components) repeats=\(repeats)"
                )
            }
        }
        return identifier
    }

    // MARK: - Attachments

    /// Adds an attachment to the notification content from a file URL.
    static func makeAttachment(
        identifier: String = UUID().uuidString, url: URL, options: [AnyHashable: Any]? = nil
    ) -> UNNotificationAttachment? {
        do {
            return try UNNotificationAttachment(identifier: identifier, url: url, options: options)
        } catch {
            print("[NotificationManager] Failed to create attachment: \(error)")
            return nil
        }
    }

    // MARK: - Management

    /// Removes pending notification requests with the specified identifiers.
    func removePending(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        if isDebugLoggingEnabled { print("[NotificationManager] Removed pending: \(identifiers)") }
    }

    /// Removes delivered notifications with the specified identifiers.
    func removeDelivered(withIdentifiers identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        if isDebugLoggingEnabled {
            print("[NotificationManager] Removed delivered: \(identifiers)")
        }
    }

    /// Removes all pending notification requests.
    func removeAllPending() { center.removeAllPendingNotificationRequests() }

    /// Removes all delivered notifications.
    func removeAllDelivered() { center.removeAllDeliveredNotifications() }

    /// Fetches all pending notifications.
    func getPending(completion: @escaping ([UNNotificationRequest]) -> Void) {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async { completion(requests) }
        }
    }

    /// Fetches all delivered notifications currently shown in Notification Center.
    func getDelivered(completion: @escaping ([UNNotification]) -> Void) {
        center.getDeliveredNotifications { notifications in
            DispatchQueue.main.async { completion(notifications) }
        }
    }
    /// Removes all pending notifications with the "reminder" category.
    func removeAllReminderNotifications(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { [weak self] requests in
            let ids = requests.filter { $0.content.categoryIdentifier == "reminder" }.map {
                $0.identifier
            }
            if !ids.isEmpty {
                self?.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Present notifications while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, list, play sound by default when in foreground.
        completionHandler([.banner, .list, .sound])
    }

    /// Handle user interaction with a notification (taps or custom actions).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if isDebugLoggingEnabled {
            print(
                "[NotificationManager] didReceive response for id=\(response.notification.request.identifier), action=\(response.actionIdentifier)"
            )
        }
        completionHandler()
    }
}
