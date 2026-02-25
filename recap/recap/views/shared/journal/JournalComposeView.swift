// JournalComposeView.swift
// recap
// Created by Copilot on 25/02/26.

import SwiftUI

struct JournalComposeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: JournalViewModel

    let patientId: String

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: String? = nil
    @State private var showingRecordingPreview = false

    private let moods: [(emoji: String, label: String, key: String)] = [
        ("😊", "Happy", "happy"),
        ("😢", "Sad", "sad"),
        ("😐", "Neutral", "neutral"),
        ("😰", "Anxious", "anxious"),
        ("😌", "Calm", "calm"),
        ("🙏", "Grateful", "grateful"),
    ]

    private var canSave: Bool {
        !content.isEmpty || viewModel.audioData != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: AppConfig.UI.spacing) {
                        moodSelector

                        titleField

                        contentField

                        audioSection
                    }
                    .padding(AppConfig.UI.screenPadding)
                }
                .disabled(viewModel.isCreating)

                // Saving overlay
                if viewModel.isCreating {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Saving…")
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(.white)
                    }
                    .padding(28)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(AppConfig.UI.cornerRadius)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.trigger(.selection)
                        viewModel.cancelRecording()
                        dismiss()
                    }
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .disabled(viewModel.isCreating)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppConfig.Colors.accent))
                    } else {
                        Button("Save") {
                            saveEntry()
                        }
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(canSave ? AppConfig.Colors.accent : AppConfig.Colors.textSecondary.opacity(0.4))
                        .disabled(!canSave)
                    }
                }
            }
            .standardBackground()
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How are you feeling?")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(moods, id: \.key) { mood in
                        Button {
                            HapticManager.shared.trigger(.selection)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMood = selectedMood == mood.key ? nil : mood.key
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 28))
                                Text(mood.label)
                                    .font(AppConfig.Fonts.small)
                                    .foregroundColor(
                                        selectedMood == mood.key ? .white : AppConfig.Colors.textSecondary
                                    )
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                selectedMood == mood.key
                                    ? AppConfig.Colors.accent
                                    : AppConfig.Colors.card
                            )
                            // .cornerRadius(AppConfig.UI.buttonCornerRadius)
                            // .overlay(
                            //     RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                            //         .stroke(
                            //             selectedMood == mood.key ? AppConfig.Colors.accent : AppConfig.Colors.stroke,
                            //             lineWidth: 1
                            //         )
                            // )
                        }
                    }
                }
            }
        }
        .padding(AppConfig.UI.padding)
        .background(AppConfig.Colors.card)
        .cornerRadius(AppConfig.UI.cornerRadius)
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            TextField("Give this memory a title...", text: $title)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .padding(AppConfig.UI.padding)
                .background(AppConfig.Colors.card)
                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                        .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                )
        }
    }

    // MARK: - Content Field

    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal Entry")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("What's on your mind today?")
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $content)
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .frame(minHeight: 200)
                    .padding(8)
                    .scrollContentBackground(.hidden)
            }
            .background(AppConfig.Colors.card)
            .cornerRadius(AppConfig.UI.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voice Note")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(spacing: 16) {
                if viewModel.isRecording {
                    recordingActiveView
                } else if viewModel.audioData != nil {
                    recordingDoneView
                } else {
                    recordingIdleView
                }
            }
            .padding(AppConfig.UI.padding)
            .frame(maxWidth: .infinity)
            .background(AppConfig.Colors.card)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
        }
    }

    private var recordingIdleView: some View {
        VStack(spacing: 12) {
            Button {
                HapticManager.shared.trigger(.medium)
                viewModel.startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppConfig.Colors.accent.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppConfig.Colors.accent)
                }
            }

            Text("Tap to record a voice note")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }

    private var recordingActiveView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isRecording)

                Text(formatDuration(viewModel.recordingDuration))
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .monospacedDigit()
            }

            Button {
                HapticManager.shared.trigger(.medium)
                viewModel.stopRecording()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop Recording")
                }
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.red)
                .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
        }
    }

    private var recordingDoneView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(AppConfig.Colors.accent)
                Text(formatDuration(viewModel.recordingDuration))
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .monospacedDigit()
            }

            HStack(spacing: 16) {
                Button {
                    HapticManager.shared.trigger(.selection)
                    if viewModel.isPlaying {
                        viewModel.stopAudio()
                    } else if let data = viewModel.audioData,
                              let url = saveToTempFile(data: data) {
                        viewModel.playAudio(from: url.absoluteString, entryId: "preview")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        Text(viewModel.isPlaying ? "Pause" : "Play")
                    }
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.accent)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(AppConfig.Colors.accent.opacity(0.1))
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }

                Button {
                    HapticManager.shared.trigger(.warning)
                    viewModel.cancelRecording()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.alert)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(AppConfig.Colors.alert.opacity(0.1))
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
            }
        }
    }

    // MARK: - Helpers

    private func saveEntry() {
        HapticManager.shared.trigger(.selection)
        let createdBy = appState.currentUser?.type == "family" ? "family" : "patient"
        let duration = viewModel.audioData != nil ? viewModel.recordingDuration : nil

        Task {
            let success = await viewModel.createEntry(
                patientId: patientId,
                title: title.isEmpty ? nil : title,
                content: content.isEmpty ? nil : content,
                mood: selectedMood,
                audioData: viewModel.audioData,
                audioDuration: duration,
                createdBy: createdBy
            )
            if success {
                HapticManager.shared.trigger(.success)
                viewModel.audioData = nil
                viewModel.recordingDuration = 0
                dismiss()
            } else {
                HapticManager.shared.trigger(.error)
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func saveToTempFile(data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview_audio.wav")
        try? data.write(to: url)
        return url
    }
}
