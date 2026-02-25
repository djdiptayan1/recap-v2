// JournalViewModel.swift
// recap
// Created by Copilot on 25/02/26.

import AVFoundation
import Combine
import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCreating = false
    @Published var isRecording = false
    @Published var audioData: Data?
    @Published var recordingDuration: Double = 0
    @Published var isPlaying = false
    @Published var playingEntryId: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var recordingTimer: Timer?

    // MARK: - API Endpoints

    private enum JournalAPI: Endpoint {
        case getEntries(patientId: String, limit: Int, after: String?)
        case getEntryById(entryId: String, patientId: String)
        case createEntry(request: JournalCreateRequest)
        case updateEntry(entryId: String, request: JournalUpdateRequest)
        case deleteEntry(entryId: String, patientId: String)

        var path: String {
            switch self {
            case .getEntries:
                return AppConfig.ApiEndpoints.journal
            case .getEntryById(let entryId, _):
                return "\(AppConfig.ApiEndpoints.journal)/\(entryId)"
            case .createEntry:
                return AppConfig.ApiEndpoints.journal
            case .updateEntry(let entryId, _):
                return "\(AppConfig.ApiEndpoints.journal)/\(entryId)"
            case .deleteEntry(let entryId, _):
                return "\(AppConfig.ApiEndpoints.journal)/\(entryId)"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .getEntries, .getEntryById: return .get
            case .createEntry: return .post
            case .updateEntry: return .put
            case .deleteEntry: return .delete
            }
        }

        var body: Encodable? {
            switch self {
            case .createEntry(let request): return request
            case .updateEntry(_, let request): return request
            default: return nil
            }
        }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .getEntries(let patientId, let limit, let after):
                var items = [
                    URLQueryItem(name: "patientId", value: patientId),
                    URLQueryItem(name: "limit", value: String(limit)),
                ]
                if let after = after {
                    items.append(URLQueryItem(name: "after", value: after))
                }
                return items
            case .getEntryById(_, let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            case .deleteEntry(_, let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            default:
                return nil
            }
        }
    }

    // MARK: - Fetch Methods

    func fetchEntries(patientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: JournalResponse = try await NetworkManager.shared.request(
                endpoint: JournalAPI.getEntries(patientId: patientId, limit: 20, after: nil),
                keyDecodingStrategy: .useDefaultKeys
            )
            if response.success {
                self.entries = response.data
            } else {
                self.errorMessage = "Failed to fetch journal entries"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching journal entries: \(error)")
        }

        isLoading = false
    }

    func createEntry(
        patientId: String,
        title: String?,
        content: String?,
        mood: String?,
        audioData: Data?,
        audioDuration: Double?,
        createdBy: String
    ) async -> Bool {
        isCreating = true
        errorMessage = nil

        let audioBase64 = audioData.map { "data:audio/wav;base64," + $0.base64EncodedString() }

        let request = JournalCreateRequest(
            patientId: patientId,
            title: title?.isEmpty == true ? nil : title,
            content: content?.isEmpty == true ? nil : content,
            mood: mood,
            audioBase64: audioBase64,
            audioDuration: audioDuration,
            createdBy: createdBy
        )

        do {
            let response: JournalSingleResponse = try await NetworkManager.shared.request(
                endpoint: JournalAPI.createEntry(request: request),
                keyDecodingStrategy: .useDefaultKeys
            )
            if response.success {
                entries.insert(response.data, at: 0)
                isCreating = false
                return true
            } else {
                errorMessage = "Failed to create journal entry"
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error creating journal entry: \(error)")
        }

        isCreating = false
        return false
    }

    func deleteEntry(entryId: String, patientId: String) async -> Bool {
        errorMessage = nil

        do {
            // Network response for delete returns success/message
            struct DeleteResponse: Decodable {
                let success: Bool
                let message: String?
            }
            let response: DeleteResponse = try await NetworkManager.shared.request(
                endpoint: JournalAPI.deleteEntry(entryId: entryId, patientId: patientId),
                keyDecodingStrategy: .useDefaultKeys
            )
            if response.success {
                entries.removeAll { $0.id == entryId }
                return true
            } else {
                errorMessage = "Failed to delete journal entry"
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting journal entry: \(error)")
        }

        return false
    }

    // MARK: - Audio Recording

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "journal_recording_\(Date().timeIntervalSince1970).wav"
        let url = tempDir.appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 0.1
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        isRecording = false

        if let url = recordingURL {
            audioData = try? Data(contentsOf: url)
        }
    }

    func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        isRecording = false
        audioData = nil
        recordingDuration = 0
        recordingURL = nil
    }

    // MARK: - Audio Playback

    func playAudio(from urlString: String, entryId: String) {
        guard let url = URL(string: urlString) else { return }

        if isPlaying && playingEntryId == entryId {
            stopAudio()
            return
        }

        stopAudio()
        playingEntryId = entryId

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                        self.audioPlayer = try AVAudioPlayer(data: data)
                        self.audioPlayer?.play()
                        self.isPlaying = true
                    } catch {
                        print("Failed to play audio: \(error)")
                        self.isPlaying = false
                        self.playingEntryId = nil
                    }
                }
            } catch {
                await MainActor.run {
                    print("Failed to download audio: \(error)")
                    self.isPlaying = false
                    self.playingEntryId = nil
                }
            }
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playingEntryId = nil
    }
}
