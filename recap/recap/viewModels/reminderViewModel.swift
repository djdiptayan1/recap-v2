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

    private let baseURL = AppConfig.ApiEndpoints.baseURL

    func fetchReminders(patientId: String) {
        guard
            let url = URL(
                string: "\(baseURL)\(AppConfig.ApiEndpoints.reminders)?patientId=\(patientId)")
        else { return }

        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(ReminderResponse.self, from: data)
                    if result.success {
                        self?.reminders = result.data
                    } else {
                        self?.errorMessage = "Failed to fetch reminders"
                    }
                } catch {
                    print("Decoding error: \(error)")
                    self?.errorMessage = "Failed to parse reminders"
                }
            }
        }.resume()
    }

    func addReminder(
        patientId: String, title: String, category: ReminderCategory, frequency: ReminderFrequency,
        time: Date, notes: String, categoryDetails: [String: String]? = nil, completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)\(AppConfig.ApiEndpoints.reminders)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Format time to ISO8601 string or stick to what backend expects
        // Backend expects 'time' field. JSONEncoder handles Date encoding, but sometimes format differs.
        // Let's use custom encoder date formatting if needed, but ISO8601 is standard.
        // However, 'time' in Reminder struct is Date.

        let newReminder = AddReminderRequest(
            patientId: patientId, title: title, category: category.rawValue,
            frequency: frequency.rawValue, time: time, notes: notes,
            categoryDetails: categoryDetails)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(newReminder)
        } catch {
            print("Encoding error: \(error)")
            completion(false)
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Add reminder error: \(error)")
                    completion(false)
                    return
                }

                guard let data = data else {
                    completion(false)
                    return
                }

                do {
                    // Start: Debugging Step - Print Response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Add Reminder Response: \(jsonString)")
                    }
                    // End: Debugging Step

                    // Check for success/failure structure first
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, !success {
                            if let errors = json["errors"] as? [[String: Any]] {
                                // Extract content from express-validator errors
                                let msgs = errors.compactMap { $0["msg"] as? String }
                                self?.errorMessage = msgs.joined(separator: ", ")
                            } else if let errorMsg = json["error"] as? String {
                                self?.errorMessage = errorMsg
                            } else {
                                self?.errorMessage = "Failed to add reminder"
                            }
                            completion(false)
                            return
                        }
                    }

                    let result = try JSONDecoder().decode(SingleReminderResponse.self, from: data)
                    if result.success {
                        self?.reminders.append(result.data)
                        completion(true)
                    } else {
                        self?.errorMessage = "Failed to add reminder"
                        completion(false)
                    }
                } catch {
                    print("Decoding error (Add): \(error)")
                    self?.errorMessage = "Failed to parse response"
                    completion(false)
                }
            }
        }.resume()
    }

    func deleteReminder(patientId: String, reminderId: String, completion: ((Bool) -> Void)? = nil)
    {
        guard let url = URL(string: "\(baseURL)\(AppConfig.ApiEndpoints.reminders)") else {
            completion?(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["patientId": patientId, "reminderId": reminderId]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error encoding delete body: \(error)")
            self.errorMessage = "Failed to encode delete request"
            completion?(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Delete error: \(error)")
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Successful delete
                    self?.reminders.removeAll { $0.id == reminderId }
                    completion?(true)
                } else {
                    self?.errorMessage = "Failed to delete reminder"
                    completion?(false)
                }
            }
        }.resume()
    }
    func editReminder(
        patientId: String, reminderId: String, title: String, category: ReminderCategory,
        frequency: ReminderFrequency, time: Date, notes: String,
        categoryDetails: [String: String]? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)\(AppConfig.ApiEndpoints.reminders)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updatedReminder = EditReminderRequest(
            patientId: patientId, reminderId: reminderId, title: title, category: category.rawValue,
            frequency: frequency.rawValue, time: time, notes: notes,
            categoryDetails: categoryDetails)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(updatedReminder)
        } catch {
            print("Encoding error: \(error)")
            completion(false)
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Edit reminder error: \(error)")
                    completion(false)
                    return
                }

                guard let data = data else {
                    completion(false)
                    return
                }

                do {
                    let result = try JSONDecoder().decode(SingleReminderResponse.self, from: data)
                    if result.success {
                        if let index = self?.reminders.firstIndex(where: { $0.id == reminderId }) {
                            self?.reminders[index] = result.data
                        }
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    print("Decoding error (Edit): \(error)")
                    completion(false)
                }
            }
        }.resume()
    }
}

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

// MARK: - Helper Structs
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
