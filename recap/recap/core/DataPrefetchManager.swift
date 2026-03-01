//
//  DataPrefetchManager.swift
//  recap
//
//  Centralized data prefetching during splash screen to reduce
//  redundant network requests when switching tabs.
//

import Combine
import Foundation

@MainActor
class DataPrefetchManager: ObservableObject {
    static let shared = DataPrefetchManager()

    // MARK: - Cached data (nil = not yet fetched)
    @Published var familyMembers: [FamilyMember]?
    @Published var streakStats: StreakStatsData?
    @Published var articles: [articleModel]?
    @Published var journalEntries: [JournalEntry]?
    @Published var reminders: [Reminder]?
    @Published var dailyQuestions: QuestionResponse?
    @Published var isPrefetching = false

    private init() {}

    // MARK: - Prefetch API Endpoints

    private enum PrefetchAPI: Endpoint {
        case familyMembers(documentID: String)
        case streakStats(documentID: String)
        case articles
        case journalEntries(patientId: String, limit: Int)
        case reminders(patientId: String)
        case dailyQuestions(patientId: String)

        var path: String {
            switch self {
            case .familyMembers(let id):
                return "\(AppConfig.ApiEndpoints.familyMembers)/\(id)"
            case .streakStats(let id):
                return "\(AppConfig.ApiEndpoints.streakStats)/\(id)"
            case .articles:
                return AppConfig.ApiEndpoints.articles
            case .journalEntries:
                return AppConfig.ApiEndpoints.journal
            case .reminders:
                return AppConfig.ApiEndpoints.reminders
            case .dailyQuestions:
                return AppConfig.ApiEndpoints.getDailyQuestions
            }
        }

        var method: HTTPMethod { .get }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .journalEntries(let patientId, let limit):
                return [
                    URLQueryItem(name: "patientId", value: patientId),
                    URLQueryItem(name: "limit", value: String(limit)),
                ]
            case .reminders(let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            case .dailyQuestions(let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            default:
                return nil
            }
        }
    }

    // MARK: - Prefetch All

    func prefetchAll(documentID: String, patientDocumentID: String) async {
        guard !documentID.isEmpty else { return }
        isPrefetching = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.prefetchFamilyMembers(documentID: documentID) }
            group.addTask { await self.prefetchStreakStats(documentID: patientDocumentID) }
            group.addTask { await self.prefetchArticles() }
            group.addTask {
                await self.prefetchJournalEntries(patientId: patientDocumentID)
            }
            group.addTask { await self.prefetchReminders(patientId: patientDocumentID) }
            group.addTask {
                await self.prefetchDailyQuestions(patientId: patientDocumentID)
            }
        }

        isPrefetching = false
    }

    // MARK: - Individual Prefetch Methods

    private func prefetchFamilyMembers(documentID: String) async {
        guard !documentID.isEmpty else { return }
        do {
            let response: FamilyMemberResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.familyMembers(documentID: documentID)
            )
            if response.success {
                self.familyMembers = response.data
            }
        } catch {
            print("[Prefetch] Family members failed: \(error)")
        }
    }

    private func prefetchStreakStats(documentID: String) async {
        guard !documentID.isEmpty else { return }
        do {
            let response: StreakStatsResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.streakStats(documentID: documentID)
            )
            if response.success {
                self.streakStats = response.data
            }
        } catch {
            print("[Prefetch] Streak stats failed: \(error)")
        }
    }

    private func prefetchArticles() async {
        do {
            let response: ArticleResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.articles
            )
            if response.success {
                self.articles = response.data
            }
        } catch {
            print("[Prefetch] Articles failed: \(error)")
        }
    }

    private func prefetchJournalEntries(patientId: String) async {
        guard !patientId.isEmpty else { return }
        do {
            let response: JournalResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.journalEntries(patientId: patientId, limit: 20),
                keyDecodingStrategy: .useDefaultKeys
            )
            if response.success {
                self.journalEntries = response.data
            }
        } catch {
            print("[Prefetch] Journal entries failed: \(error)")
        }
    }

    private func prefetchReminders(patientId: String) async {
        guard !patientId.isEmpty else { return }
        do {
            let response: ReminderResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.reminders(patientId: patientId)
            )
            if response.success {
                self.reminders = response.data
            }
        } catch {
            print("[Prefetch] Reminders failed: \(error)")
        }
    }

    private func prefetchDailyQuestions(patientId: String) async {
        guard !patientId.isEmpty else { return }
        do {
            let response: QuestionResponse = try await NetworkManager.shared.request(
                endpoint: PrefetchAPI.dailyQuestions(patientId: patientId),
                keyDecodingStrategy: .useDefaultKeys
            )
            self.dailyQuestions = response
        } catch {
            print("[Prefetch] Daily questions failed: \(error)")
        }
    }

    // MARK: - Cache Invalidation

    func invalidateAll() {
        familyMembers = nil
        streakStats = nil
        articles = nil
        journalEntries = nil
        reminders = nil
        dailyQuestions = nil
    }

    func invalidateFamilyMembers() { familyMembers = nil }
    func invalidateStreakStats() { streakStats = nil }
    func invalidateArticles() { articles = nil }
    func invalidateJournalEntries() { journalEntries = nil }
    func invalidateReminders() { reminders = nil }
    func invalidateDailyQuestions() { dailyQuestions = nil }
}
