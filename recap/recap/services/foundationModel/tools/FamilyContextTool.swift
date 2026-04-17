//
//  FamilyContextTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

private actor FamilyContextCache {
    static let shared = FamilyContextCache()
    private var entries: [String: (timestamp: Date, payload: String)] = [:]

    func value(for key: String, maxAge: TimeInterval) -> String? {
        guard let entry = entries[key] else { return nil }
        guard Date().timeIntervalSince(entry.timestamp) <= maxAge else {
            entries.removeValue(forKey: key)
            return nil
        }
        return entry.payload
    }

    func set(_ value: String, for key: String) {
        entries[key] = (timestamp: Date(), payload: value)
    }
}

struct FamilyContextTool: Tool {
    let name = "getFamilyContext"
    let description = "Fetches family members linked to the patient"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Include contact information in the summary")
        var includeContact: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let cacheKey = "\(patientId)|\(arguments.includeContact)"
        if let cached = await FamilyContextCache.shared.value(for: cacheKey, maxAge: 45) {
            return cached
        }

        let response: FamilyMemberResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.familyMembers(documentID: patientId)
        )
        let members = response.data.prefix(6).map { member in
            if arguments.includeContact {
                return "\(member.name) (\(member.relation)) | \(member.phone) | \(member.email)"
            }
            return "\(member.name) (\(member.relation))"
        }
        let summary = members.isEmpty
            ? "No family members are available."
            : "Family members: \(members.joined(separator: "; "))"

        await FamilyContextCache.shared.set(summary, for: cacheKey)
        return summary
    }
}
#endif
