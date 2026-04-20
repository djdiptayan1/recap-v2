//
//  ReminderWriteTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct ReminderWriteTool: Tool {
    let name = "writeReminder"
    let description = "Creates a patient reminder only after explicit user confirmation"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Reminder title")
        var title: String?

        @Guide(description: "Reminder category. One of: Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other")
        var category: String?

        @Guide(description: "Reminder frequency. One of: once, hourly, daily, weekdays, weekends, weekly, biweekly, monthly, yearly")
        var frequency: String?

        @Guide(description: "24-hour time in HH:mm format")
        var time24h: String?

        @Guide(description: "Optional ISO date as yyyy-MM-dd for one-time reminders")
        var dateISO: String?

        @Guide(description: "Optional note for the reminder")
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
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        guard let title = arguments.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let rawCategory = arguments.category,
              let rawFrequency = arguments.frequency,
              let time24h = arguments.time24h else {
            return "Reminder not created: missing required fields (title, category, frequency, time24h). Ask the user."
        }

        guard let category = ReminderCategory.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(rawCategory) == .orderedSame
        }) else {
            return "Reminder not created: invalid category."
        }

        guard let frequency = ReminderFrequency.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(rawFrequency) == .orderedSame
        }) else {
            return "Reminder not created: invalid frequency."
        }

        guard let reminderDate = parseReminderDate(time24h: time24h, dateISO: arguments.dateISO) else {
            return "Reminder not created: invalid time format. Use HH:mm and optional yyyy-MM-dd."
        }

        let categoryDetails = buildCategoryDetails(from: arguments)
        let missing = ReminderDetailsValidator.missingKeys(for: category, details: categoryDetails)
        if !missing.isEmpty {
            return "Reminder not created: missing required details for \(category.rawValue): \(missing.joined(separator: ", ")). Ask the user for these values and try again."
        }

        let request = ToolAddReminderRequest(
            patientId: patientId,
            title: title,
            category: category.rawValue,
            frequency: frequency.rawValue,
            time: reminderDate,
            notes: normalizedOptional(arguments.notes),
            categoryDetails: categoryDetails.isEmpty ? nil : categoryDetails
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)

        let response: SingleReminderResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.addReminder(body: body)
        )

        if response.success {
            return "Reminder created successfully: id=\(response.data.id), title=\(response.data.title)."
        }
        return "Reminder could not be created due to backend failure."
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

        if let dateISO, !dateISO.isEmpty {
            let dateParts = dateISO.split(separator: "-")
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
}
#endif
