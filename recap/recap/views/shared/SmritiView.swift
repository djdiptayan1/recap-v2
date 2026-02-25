//
//  SmritiView.swift
//  recap
//
//  Created by Diptayan Jash on 08/01/26.
//

import SwiftUI

struct SmritiView: View {
    @StateObject private var viewModel = SmritiViewModel()
    @EnvironmentObject var appState: AppState
    @State private var textInput: String = ""
    @State private var showCamera: Bool = false
    @State private var familyMembers: [FamilyMember]? = nil

    // Endpoint for fetching family members
    private enum FamilyAPI: Endpoint {
        case fetch(documentID: String)
        var path: String {
            switch self {
            case .fetch(let documentID):
                return AppConfig.ApiEndpoints.familyMembers + "/\(documentID)"
            }
        }
        var method: HTTPMethod { .get }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                Spacer().frame(height: 20)

                                // Chat Bubbles
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .padding()
                                            .background(.ultraThinMaterial, in: Circle())
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("loading")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastId = viewModel.messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { loading in
                            if loading {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                VStack {
                    Spacer()
                    InputBar(text: $textInput, showCamera: $showCamera, onSend: sendMessage)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Smriti")
            .standardBackground()
            .task {
                await loadContext()
            }
        }
    }

    private func loadContext() async {
        let patient = appState.currentUser
        let docId = KeychainManager.shared.getString(key: .patientDocumentID) ?? patient?.id ?? ""
        var members: [FamilyMember]? = nil
        if !docId.isEmpty {
            let response: FamilyMemberResponse? = try? await NetworkManager.shared.request(
                endpoint: FamilyAPI.fetch(documentID: docId))
            members = response?.data
        }
        familyMembers = members
        viewModel.configure(patient: patient, familyMembers: members)
    }

    func sendMessage() {
        guard !textInput.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let textToSend = textInput
        textInput = ""  // Clear immediately

        // Let ViewModel handle the networking and list updating
        viewModel.sendMessage(text: textToSend)
    }
}

struct InputBar: View {
    @Binding var text: String
    @Binding var showCamera: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {

            Button(action: { showCamera.toggle() }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(
                        ConcentricRectangle(corners: .concentric)
                            .foregroundStyle(.ultraThinMaterial)
                    )
                    .containerShape(Circle())
            }

            HStack {
                TextField("Ask Smriti...", text: $text)
                    .foregroundStyle(.primary)
                    .tint(.white)
                    .padding(.leading, 12)

                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Color.blue.gradient
                        )
                        .clipShape(Circle())
                }
                .padding(4)
                .disabled(text.isEmpty)
                .opacity(text.isEmpty ? 0.6 : 1.0)
            }
            .frame(height: 52)
            .glassEffect(.regular, in: .capsule)
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser { Spacer() }

            Text(LocalizedStringKey(message.text))  // Use LocalizedStringKey to support Markdown!
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    message.isUser
                        ? AnyShapeStyle(Color.blue.gradient)
                        : AnyShapeStyle(Color.yellow.gradient)  // Or a different color for AI
                )
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: message.isUser ? 20 : 4,
                        bottomTrailingRadius: message.isUser ? 4 : 20,
                        topTrailingRadius: 20
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)

            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    SmritiView()
        .environmentObject(AppState())
}
