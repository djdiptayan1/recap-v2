//
//  ReminderDeleteTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct ReminderDeleteTool: Tool {
    let name = "deleteReminder"
    let description = "Deletes an existing patient reminder only after explicit user confirmation"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Reminder ID to delete")
        var reminderId: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let trimmedId = arguments.reminderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            return "Reminder not deleted: reminder ID is required."
        }

        let request = ToolDeleteReminderRequest(patientId: patientId, reminderId: trimmedId)
        let response: DeleteReminderResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.deleteReminder(body: request)
        )

        if response.success {
            return "Reminder deleted successfully: id=\(trimmedId)."
        }
        return "Reminder could not be deleted due to backend failure."
    }
}
#endif
