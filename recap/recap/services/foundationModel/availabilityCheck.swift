//
//  availabilityCheck.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AIProviderKind {
	case foundation
	case gemini
}

enum FoundationAvailabilityKind {
	case notEnabled
	case preparing
}

struct FoundationAvailabilityPrompt {
	let kind: FoundationAvailabilityKind
	let title: String
	let message: String
}

struct FoundationAvailabilityDecision {
	let provider: AIProviderKind
	let prompt: FoundationAvailabilityPrompt?
}

@MainActor
final class FoundationAvailabilityService {
	static let shared = FoundationAvailabilityService()
	private init() {}

	func resolveProvider() async -> FoundationAvailabilityDecision {
#if canImport(FoundationModels)
		let model = SystemLanguageModel.default

		switch model.availability {
		case .available:
			let ready = await runReadinessProbe(model: model)
			if ready {
				return FoundationAvailabilityDecision(provider: .foundation, prompt: nil)
			}

			return FoundationAvailabilityDecision(
				provider: .foundation,
				prompt: FoundationAvailabilityPrompt(
					kind: .preparing,
					title: "Apple Intelligence is preparing",
					message:
						"The on-device model is still downloading or initializing. Please open Settings if needed, then return and tap Retry."
				)
			)

		case .unavailable(.appleIntelligenceNotEnabled):
			return FoundationAvailabilityDecision(
				provider: .foundation,
				prompt: FoundationAvailabilityPrompt(
					kind: .notEnabled,
					title: "Enable Apple Intelligence",
					message:
						"Apple Intelligence is available on this device but currently turned off. Enable it in Settings to use on-device Smriti."
				)
			)

		case .unavailable(.modelNotReady):
			return FoundationAvailabilityDecision(
				provider: .foundation,
				prompt: FoundationAvailabilityPrompt(
					kind: .preparing,
					title: "Apple Intelligence is preparing",
					message:
						"Apple Intelligence is still downloading or preparing. Open Settings to check status, then return and tap Retry."
				)
			)

		case .unavailable(.deviceNotEligible):
			return FoundationAvailabilityDecision(provider: .gemini, prompt: nil)

		case .unavailable:
			return FoundationAvailabilityDecision(
				provider: .foundation,
				prompt: FoundationAvailabilityPrompt(
					kind: .preparing,
					title: "Apple Intelligence is unavailable right now",
					message:
						"This device supports Apple Intelligence, but it is currently unavailable. Please check Settings and try Retry."
				)
			)
		}
#else
		return FoundationAvailabilityDecision(provider: .gemini, prompt: nil)
#endif
	}

#if canImport(FoundationModels)
	private func runReadinessProbe(model: SystemLanguageModel) async -> Bool {
		do {
			let session = LanguageModelSession(model: model)
			_ = try await session.respond(
				to: "Reply with the single word READY.",
				options: GenerationOptions(temperature: 0)
			)
			return true
		} catch {
			return false
		}
	}
#endif
}
