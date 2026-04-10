//
//  reminderViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 18/01/26.
//

import Combine
import Foundation
import SwiftUI

class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - API Endpoints

    private enum ReminderAPI: Endpoint {
        case fetch(patientId: String)
        case add(body: Data)
        case edit(body: Data)
        case delete(request: DeleteReminderRequest)
        case complete(body: Data)
        case snooze(body: Data)

        var path: String {
            switch self {
            case .complete:
                return "\(AppConfig.ApiEndpoints.reminders)/complete"
            case .snooze:
                return "\(AppConfig.ApiEndpoints.reminders)/snooze"
            case .fetch, .add, .edit, .delete:
                return AppConfig.ApiEndpoints.reminders
            }
        }

        var method: HTTPMethod {
            switch self {
            case .fetch: return .get
            case .add: return .post
            case .edit: return .put
            case .delete: return .delete
            case .complete, .snooze: return .post
            }
        }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .fetch(let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            default:
                return nil
            }
        }

        var body: Encodable? {
            switch self {
            case .add(let data): return data
            case .edit(let data): return data
            case .delete(let request): return request
            case .complete(let data): return data
            case .snooze(let data): return data
            default: return nil
            }
        }
    }

    // MARK: - Fetch Methods

    @MainActor
    func fetchReminders(patientId: String, forceRefresh: Bool = false) async {
        guard forceRefresh || reminders.isEmpty else { return }

        // Use prefetched data if available
        if !forceRefresh, let cached = DataPrefetchManager.shared.reminders {
            self.reminders = cached
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: ReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.fetch(patientId: patientId)
            )
            if response.success {
                self.reminders = response.data
            } else {
                self.errorMessage = "Failed to fetch reminders"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching reminders: \(error)")
        }

        isLoading = false
    }

    @MainActor
    func addReminder(
        patientId: String, title: String, category: ReminderCategory, frequency: ReminderFrequency,
        time: Date, notes: String, categoryDetails: [String: String]? = nil
    ) async -> Bool {
        let request = AddReminderRequest(
            patientId: patientId, title: title, category: category.rawValue,
            frequency: frequency.rawValue, time: time, notes: notes,
            categoryDetails: categoryDetails)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let bodyData = try? encoder.encode(request) else {
            self.errorMessage = "Failed to encode reminder"
            print("Error encoding add reminder request")
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: SingleReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.add(body: bodyData)
            )
            isLoading = false
            if response.success {
                self.reminders.append(response.data)
                return true
            } else {
                self.errorMessage = "Failed to add reminder"
                return false
            }
        } catch {
            isLoading = false
            self.errorMessage = error.localizedDescription
            print("Error adding reminder: \(error)")
            return false
        }
    }

    @MainActor
    func deleteReminder(patientId: String, reminderId: String) async -> Bool {
        errorMessage = nil

        let request = DeleteReminderRequest(patientId: patientId, reminderId: reminderId)

        do {
            let response: DeleteReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.delete(request: request)
            )
            if response.success {
                self.reminders.removeAll { $0.id == reminderId }
                return true
            } else {
                self.errorMessage = "Failed to delete reminder"
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error deleting reminder: \(error)")
            return false
        }
    }

    @MainActor
    func editReminder(
        patientId: String, reminderId: String, title: String, category: ReminderCategory,
        frequency: ReminderFrequency, time: Date, notes: String,
        categoryDetails: [String: String]? = nil
    ) async -> Bool {
        let request = EditReminderRequest(
            patientId: patientId, reminderId: reminderId, title: title, category: category.rawValue,
            frequency: frequency.rawValue, time: time, notes: notes,
            categoryDetails: categoryDetails)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let bodyData = try? encoder.encode(request) else {
            self.errorMessage = "Failed to encode reminder"
            print("Error encoding edit reminder request")
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: SingleReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.edit(body: bodyData)
            )
            isLoading = false
            if response.success {
                if let index = self.reminders.firstIndex(where: { $0.id == reminderId }) {
                    self.reminders[index] = response.data
                }
                return true
            } else {
                self.errorMessage = "Failed to edit reminder"
                return false
            }
        } catch {
            isLoading = false
            self.errorMessage = error.localizedDescription
            print("Error editing reminder: \(error)")
            return false
        }
    }

    @MainActor
    func markReminderCompleted(
        patientId: String,
        reminderId: String,
        completedVia: String = "in_app"
    ) async -> Bool {
        let request = ReminderCompleteRequest(
            patientId: patientId,
            reminderId: reminderId,
            completedVia: completedVia,
            completedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let bodyData = try? encoder.encode(request) else {
            self.errorMessage = "Failed to encode reminder completion request"
            return false
        }

        do {
            let response: SingleReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.complete(body: bodyData)
            )

            if response.success {
                if let index = self.reminders.firstIndex(where: { $0.id == reminderId }) {
                    self.reminders[index] = response.data
                }
                return true
            }

            self.errorMessage = "Failed to mark reminder complete"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error marking reminder complete: \(error)")
            return false
        }
    }

    @MainActor
    func snoozeReminder(
        patientId: String,
        reminderId: String,
        snoozeMinutes: Int = 15,
        snoozedVia: String = "in_app"
    ) async -> Bool {
        let request = ReminderSnoozeRequest(
            patientId: patientId,
            reminderId: reminderId,
            snoozeMinutes: snoozeMinutes,
            snoozedVia: snoozedVia
        )

        guard let bodyData = try? JSONEncoder().encode(request) else {
            self.errorMessage = "Failed to encode reminder snooze request"
            return false
        }

        do {
            let response: SingleReminderResponse = try await NetworkManager.shared.request(
                endpoint: ReminderAPI.snooze(body: bodyData)
            )

            if response.success {
                if let index = self.reminders.firstIndex(where: { $0.id == reminderId }) {
                    self.reminders[index] = response.data
                }
                return true
            }

            self.errorMessage = "Failed to snooze reminder"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error snoozing reminder: \(error)")
            return false
        }
    }
}

// MARK: - Request / Response Structs

struct EditReminderRequest: Codable {
    let patientId: String
    let reminderId: String
    let title: String
    let category: String
    let frequency: String
    let time: Date
    let notes: String
    let categoryDetails: [String: String]?
}

struct DeleteReminderRequest: Codable {
    let patientId: String
    let reminderId: String
}

struct ReminderCompleteRequest: Codable {
    let patientId: String
    let reminderId: String
    let completedVia: String
    let completedAt: Date
}

struct ReminderSnoozeRequest: Codable {
    let patientId: String
    let reminderId: String
    let snoozeMinutes: Int
    let snoozedVia: String
}

struct DeleteReminderResponse: Codable {
    let success: Bool
    let message: String?
}

struct ReminderResponse: Codable {
    let success: Bool
    let data: [Reminder]
}

struct SingleReminderResponse: Codable {
    let success: Bool
    let data: Reminder
}

struct AddReminderRequest: Codable {
    let patientId: String
    let title: String
    let category: String
    let frequency: String
    let time: Date
    let notes: String
    let categoryDetails: [String: String]?
}
