import Combine
import Foundation

@MainActor
final class DailyMoodViewModel: ObservableObject {
    @Published var todayEntry: DailyMoodEntry?
    @Published var history: [DailyMoodEntry] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    func refresh(patientId: String, historyDays: Int = 7) async {
        guard !patientId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        async let today = DailyMoodService.shared.fetchTodayMood(patientId: patientId)
        async let history = DailyMoodService.shared.fetchMoodHistory(patientId: patientId, days: historyDays)

        do {
            self.todayEntry = try await today
            self.history = try await history
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchToday(patientId: String) async {
        guard !patientId.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            todayEntry = try await DailyMoodService.shared.fetchTodayMood(patientId: patientId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func saveMood(patientId: String, mood: DailyMoodKey) async -> DailyMoodEntry? {
        guard !patientId.isEmpty else { return nil }

        isSaving = true
        errorMessage = nil

        do {
            let saved = try await DailyMoodService.shared.saveMood(patientId: patientId, mood: mood)
            todayEntry = saved
            if let saved {
                history.removeAll { $0.id == saved.id }
                history.insert(saved, at: 0)
                history = Array(history.prefix(7))
            }
            isSaving = false
            return saved
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return nil
        }
    }
}
