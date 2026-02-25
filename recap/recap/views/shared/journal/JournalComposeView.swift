// JournalComposeView.swift
// recap
// Created by Copilot on 25/02/26.

import PhotosUI
import SwiftUI

struct JournalComposeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: JournalViewModel

    let patientId: String

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: String? = nil
    // Memory-book fields
    @State private var people: String = ""
    @State private var place: String = ""
    @State private var eventTag: String = ""
    // Photos
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var photoPreviews: [(image: UIImage, caption: String)] = []

    private let moods: [(emoji: String, label: String, key: String)] = [
        ("😊", "Happy", "happy"),
        ("😢", "Sad", "sad"),
        ("😐", "Neutral", "neutral"),
        ("😰", "Anxious", "anxious"),
        ("😌", "Calm", "calm"),
        ("🙏", "Grateful", "grateful"),
    ]

    private var isPatient: Bool {
        appState.currentUser?.type != "family"
    }

    private var canSave: Bool {
        !title.isEmpty
        && (isPatient ? selectedMood != nil : true)
        && (!content.isEmpty || viewModel.audioData != nil || !photoPreviews.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: AppConfig.UI.spacing) {
                        moodSelector
                        titleField
                        contentField
                        photoSection
                        if !photoPreviews.isEmpty { memoryMetadataSection }
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
            .onChange(of: selectedPhotoItems) { items in
                loadSelectedPhotos(from: items)
            }
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("How are you feeling?")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                if isPatient {
                    Text("*")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.alert)
                }
            }

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
                        }
                    }
                }
            }

            if isPatient && selectedMood == nil {
                // validation indicated by * star only; no extra text
            }
        }
        .padding(AppConfig.UI.padding)
        .background(AppConfig.Colors.card)
        .cornerRadius(AppConfig.UI.cornerRadius)
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("Title")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                Text("*")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.alert)
            }

            TextField("Give this memory a title...", text: $title)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .padding(AppConfig.UI.padding)
                .background(AppConfig.Colors.card)
                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                        .stroke(title.isEmpty ? AppConfig.Colors.alert.opacity(0.5) : AppConfig.Colors.stroke, lineWidth: 1)
                )

            if title.isEmpty {
                // validation indicated by * star only; no extra text
            }
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
                    .frame(minHeight: 160)
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

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Photos")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                Spacer()
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.accent)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(AppConfig.Colors.accent.opacity(0.1))
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
            }

            if photoPreviews.isEmpty {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppConfig.Colors.accent.opacity(0.12))
                                .frame(width: 60, height: 60)
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 26))
                                .foregroundColor(AppConfig.Colors.accent)
                        }
                        Text("Add photos from your camera roll")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppConfig.Colors.card)
                    .cornerRadius(AppConfig.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                            .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                    )
                }
            } else {
                photoGrid
            }
        }
    }

    private var photoGrid: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photoPreviews.indices, id: \.self) { idx in
                        photoTile(index: idx)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func photoTile(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: photoPreviews[index].image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius))

                Button {
                    HapticManager.shared.trigger(.warning)
                    photoPreviews.remove(at: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding(4)
            }

            TextField("Caption…", text: Binding(
                get: { photoPreviews[index].caption },
                set: { photoPreviews[index].caption = $0 }
            ))
            .font(AppConfig.Fonts.small)
            .foregroundColor(AppConfig.Colors.textPrimary)
            .frame(width: 120)
        }
    }

    // MARK: - Memory Metadata (shown when photos are present)

    private var memoryMetadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Details")
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            metadataField(icon: "person.2.fill", placeholder: "Who's in this photo? (e.g. Mum, Dad)", text: $people)
            metadataField(icon: "mappin.circle.fill", placeholder: "Where was this? (e.g. Home, Mumbai)", text: $place)
            metadataField(icon: "tag.fill", placeholder: "Occasion (e.g. Birthday, Holiday, Daily life)", text: $eventTag)
        }
        .padding(AppConfig.UI.padding)
        .background(AppConfig.Colors.card)
        .cornerRadius(AppConfig.UI.cornerRadius)
    }

    private func metadataField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppConfig.Colors.accent)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textPrimary)
        }
        .padding(AppConfig.UI.padding)
        .background(AppConfig.Colors.background)
        .cornerRadius(AppConfig.UI.buttonCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
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
        let uploads: [JournalPhotoUpload]? = photoPreviews.isEmpty ? nil : photoPreviews.map {
            let jpeg = $0.image.jpegData(compressionQuality: 0.8) ?? Data()
            return JournalPhotoUpload(
                imageBase64: "data:image/jpeg;base64," + jpeg.base64EncodedString(),
                caption: $0.caption.isEmpty ? nil : $0.caption
            )
        }
        let resolvedType: String? = uploads != nil ? "memory" : nil

        Task {
            let success = await viewModel.createEntry(
                patientId: patientId,
                title: title.isEmpty ? nil : title,
                content: content.isEmpty ? nil : content,
                mood: selectedMood,
                audioData: viewModel.audioData,
                audioDuration: duration,
                createdBy: createdBy,
                entryType: resolvedType,
                people: people.isEmpty ? nil : people,
                place: place.isEmpty ? nil : place,
                eventTag: eventTag.isEmpty ? nil : eventTag,
                photoUploads: uploads
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

    private func loadSelectedPhotos(from items: [PhotosPickerItem]) {
        Task {
            var newPreviews: [(image: UIImage, caption: String)] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    newPreviews.append((image: uiImage, caption: ""))
                }
            }
            await MainActor.run {
                photoPreviews = newPreviews
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
