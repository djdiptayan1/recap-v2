//
//  ReminderEditTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct ReminderEditTool: Tool {
    let name = "editReminder"
    let description = "Edits an existing patient reminder only after explicit user confirmation"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Reminder ID to edit")
        var reminderId: String

        @Guide(description: "Optional new title")
        var title: String?

        @Guide(description: "Optional new category. One of: Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other")
        var category: String?

        @Guide(description: "Optional new frequency. One of: once, hourly, daily, weekdays, weekends, weekly, biweekly, monthly, yearly")
        var frequency: String?

        @Guide(description: "Optional new 24-hour time in HH:mm format")
        var time24h: String?

        @Guide(description: "Optional ISO date as yyyy-MM-dd for one-time reminders")
        var dateISO: String?

        @Guide(description: "Optional new note")
        var notes: String?

        @Guide(description: "Medicine name when category is Medicine")
        var medicineName: String?

        @Guide(description: "Dosage value when category is Medicine")
        var dosage: String?

        @Guide(description: "Dosage unit when category is Medicine")
        var dosageUnit: String?

        @Guide(description: "Meal relation when category is Medicine")
        var mealRelation: String?

        @Guide(description: "Doctor or person name when category is Appointment")
        var doctorName: String?

        @Guide(description: "Location when category is Appointment")
        var location: String?

        @Guide(description: "Exercise type when category is Exercise")
        var exerciseType: String?

        @Guide(description: "Duration when category is Exercise")
        var duration: String?

        @Guide(description: "Meal type when category is Meal")
        var mealType: String?

        @Guide(description: "Hydration amount when category is Hydration")
        var amount: String?

        @Guide(description: "Hydration unit when category is Hydration")
        var unit: String?

        @Guide(description: "Must be true only when user has explicitly confirmed reminder edit")
        var userConfirmed: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        guard arguments.userConfirmed else {
            return "Reminder not edited: explicit confirmation is required. Ask the user to confirm first."
        }

        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let trimmedId = arguments.reminderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            return "Reminder not edited: reminder ID is required."
        }

        var mappedCategory: String?
        if let rawCategory = normalizedOptional(arguments.category) {
            guard let category = ReminderCategory.allCases.first(where: {
                $0.rawValue.caseInsensitiveCompare(rawCategory) == .orderedSame
            }) else {
                return "Reminder not edited: invalid category."
            }
            mappedCategory = category.rawValue
        }

        var mappedFrequency: String?
        if let rawFrequency = normalizedOptional(arguments.frequency) {
            guard let frequency = ReminderFrequency.allCases.first(where: {
                $0.rawValue.caseInsensitiveCompare(rawFrequency) == .orderedSame
            }) else {
                return "Reminder not edited: invalid frequency."
            }
            mappedFrequency = frequency.rawValue
        }

        var mappedTime: Date?
        if let time24h = normalizedOptional(arguments.time24h) {
            guard let parsed = parseReminderDate(time24h: time24h, dateISO: arguments.dateISO) else {
                return "Reminder not edited: invalid time format. Use HH:mm and optional yyyy-MM-dd."
            }
            mappedTime = parsed
        }

        let existingReminder = try await fetchReminderById(patientId: patientId, reminderId: trimmedId)
        let effectiveCategory = mappedCategory.flatMap { raw in
            ReminderCategory.allCases.first { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }
        } ?? existingReminder.category

        let inputDetails = buildCategoryDetails(from: arguments)
        let effectiveDetails = mergeDetails(existing: existingReminder.categoryDetails, incoming: inputDetails)
        let needsValidation = mappedCategory != nil || !inputDetails.isEmpty
        if needsValidation {
            let missing = ReminderDetailsValidator.missingKeys(for: effectiveCategory, details: effectiveDetails)
            if !missing.isEmpty {
                return "Reminder not edited: missing required details for \(effectiveCategory.rawValue): \(missing.joined(separator: ", ")). Ask the user for these values and try again."
            }
        }

        let request = ToolEditReminderRequest(
            patientId: patientId,
            reminderId: trimmedId,
            title: normalizedOptional(arguments.title),
            category: mappedCategory,
            frequency: mappedFrequency,
            time: mappedTime,
            notes: normalizedOptional(arguments.notes),
            categoryDetails: inputDetails.isEmpty ? nil : effectiveDetails
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)

        let response: SingleReminderResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.editReminder(body: body)
        )

        if response.success {
            return "Reminder edited successfully: id=\(response.data.id), title=\(response.data.title)."
        }
        return "Reminder could not be edited due to backend failure."
    }

    private func parseReminderDate(time24h: String, dateISO: String?) -> Date? {
        let timeParts = time24h.split(separator: ":")
        guard timeParts.count == 2,
            let hour = Int(timeParts[0]),
            let minute = Int(timeParts[1]),
            (0...23).contains(hour),
            (0...59).contains(minute)
        else {
            return nil
        }

        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        if let dateISO,
            let normalizedDate = normalizedOptional(dateISO)
        {
            let dateParts = normalizedDate.split(separator: "-")
            if dateParts.count == 3,
                let y = Int(dateParts[0]),
                let m = Int(dateParts[1]),
                let d = Int(dateParts[2])
            {
                components.year = y
                components.month = m
                components.day = d
            }
        }

        return calendar.date(from: components)
    }

    private func normalizedOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func buildCategoryDetails(from args: Arguments) -> [String: String] {
        var details: [String: String] = [:]

        put(&details, key: "medicineName", value: args.medicineName)
        put(&details, key: "dosage", value: args.dosage)
        put(&details, key: "dosageUnit", value: args.dosageUnit)
        put(&details, key: "mealRelation", value: args.mealRelation)
        put(&details, key: "doctorName", value: args.doctorName)
        put(&details, key: "location", value: args.location)
        put(&details, key: "exerciseType", value: args.exerciseType)
        put(&details, key: "duration", value: args.duration)
        put(&details, key: "mealType", value: args.mealType)
        put(&details, key: "amount", value: args.amount)
        put(&details, key: "unit", value: args.unit)

        return details
    }

    private func put(_ details: inout [String: String], key: String, value: String?) {
        if let trimmed = normalizedOptional(value) {
            details[key] = trimmed
        }
    }

    private func mergeDetails(existing: [String: String]?, incoming: [String: String]) -> [String: String] {
        var merged = existing ?? [:]
        for (key, value) in incoming {
            merged[key] = value
        }
        return merged
    }

    private func fetchReminderById(patientId: String, reminderId: String) async throws -> Reminder {
        let response: ReminderResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.reminders(patientId: patientId)
        )
        if let reminder = response.data.first(where: { $0.id == reminderId }) {
            return reminder
        }
        throw SmritiToolError.networkFailure
    }
}
#endif
