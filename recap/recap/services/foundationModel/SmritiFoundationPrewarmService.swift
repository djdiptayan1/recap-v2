//
//  SmritiFoundationPrewarmService.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class SmritiFoundationPrewarmService {
    static let shared = SmritiFoundationPrewarmService()
    private init() {}

#if canImport(FoundationModels)
    private var didPrewarm = false
    private var prewarmTask: Task<Void, Never>?
#endif

    func prewarmIfPossible() {
#if canImport(FoundationModels)
        guard !didPrewarm else { return }
        guard prewarmTask == nil else { return }
        guard SystemLanguageModel.default.availability == .available else { return }

        prewarmTask = Task { [weak self] in
            guard let self else { return }
            defer { self.prewarmTask = nil }

            let session = LanguageModelSession(model: .default)
            session.prewarm()
            self.didPrewarm = true
        }
#endif
    }
}
