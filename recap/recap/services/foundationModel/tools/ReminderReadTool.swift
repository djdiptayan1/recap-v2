//
//  ReminderReadTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct ReminderReadTool: Tool {
    let name = "getReminders"
    let description = "Fetches upcoming reminders for the patient"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Maximum number of reminders to summarize", .range(1...10))
        var limit: Int
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }
        let response: ReminderResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.reminders(patientId: patientId)
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let reminders = response.data.prefix(max(1, arguments.limit)).map { reminder in
            let time = formatter.string(from: reminder.time)
            return "id=\(reminder.id) | \(reminder.title) at \(time) [\(reminder.category.rawValue)]"
        }

        if reminders.isEmpty { return "No reminders are set." }
        return "Upcoming reminders: \(reminders.joined(separator: "; "))"
    }
}
#endif
