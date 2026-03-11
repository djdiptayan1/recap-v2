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
    @State private var isMemoryLaneMode: Bool = false

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
                                Spacer().frame(height: 12)

                                // Chat Bubbles
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                // Typing indicator
                                if viewModel.isLoading {
                                    HStack(spacing: 8) {
                                        ThinkingDots()
                                        Text("Smriti is thinking...")
                                            .font(
                                                .system(size: 14, weight: .medium, design: .rounded)
                                            )
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("loading")
                                }

                                // Follow-up prompt chip
                                if let followup = viewModel.followupPrompt, !viewModel.isLoading {
                                    FollowupChip(text: followup) {
                                        textInput = followup
                                    }
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(
                                                with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                                    .id("followup")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: viewModel.messages.count) { _ in
                            scrollToBottom(proxy)
                        }
                        .onChange(of: viewModel.messages.last?.text) { _ in
                            if let lastId = viewModel.messages.last?.id {
                                withAnimation(.easeOut(duration: 0.1)) {
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
                        .onChange(of: viewModel.followupPrompt) { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo("followup", anchor: .bottom)
                            }
                        }
                    }
                }

                VStack {
                    Spacer()

                    // Rate limit banner
                    if viewModel.isRateLimited {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.orange)
                            Text(
                                viewModel.rateLimitMessage
                                    ?? "Message limit reached. Try again later."
                            )
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        InputBar(text: $textInput, showCamera: $showCamera, onSend: sendMessage)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .disabled(viewModel.isLoading)
                    }
                }
            }
            .navigationTitle(isMemoryLaneMode ? "Smriti" : "Care Assistant")
            .standardBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
//                    if let usage = viewModel.usageInfo, !viewModel.isRateLimited {
//                        Text("\(usage.dailyRemaining)/\(usage.dailyLimit)")
//                            .font(AppConfig.Fonts.small)
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 4)
//                            .fixedSize()
//                    }
                    Group {
                            if let usage = viewModel.usageInfo, !viewModel.isRateLimited {
                                Text("\(usage.dailyRemaining)/\(usage.dailyLimit)")
                            } else {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        .frame(width: 40)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        isMemoryLaneMode ? "Care Assistant" : "Smriti",
                        systemImage: isMemoryLaneMode ? "sparkles" : "brain.head.profile"
                    ) {
                        isMemoryLaneMode.toggle()
                        HapticManager.shared.trigger(.medium)
                        viewModel.setMemoryLaneMode(isMemoryLaneMode)
                    }
                    .tint(isMemoryLaneMode ? .primary : .orange)
                }
            }
            .task {
                await loadContext()
                await viewModel.fetchUsage()
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRateLimited)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func loadContext() async {
        let patient = appState.currentUser
        let isPatient = patient?.type == "patient"

        // Use animation strictly to set the initial mode cleanly without visual jump if possible
        withAnimation {
            isMemoryLaneMode = isPatient
        }

        let docId = KeychainManager.shared.getString(key: .patientDocumentID) ?? patient?.id ?? ""
        var members: [FamilyMember]?
        if !docId.isEmpty {
            let response: FamilyMemberResponse? = try? await NetworkManager.shared.request(
                endpoint: FamilyAPI.fetch(documentID: docId))
            members = response?.data
        }
        familyMembers = members

        var streakDays: Int?
        if let cachedStreak = UserDefaults.standard.object(forKey: "currentStreakDays") as? Int {
            streakDays = cachedStreak
        }

        viewModel.configure(
            patient: patient,
            familyMembers: members,
            streakDays: streakDays,
            reminderTitles: nil,
            isMemoryLane: isPatient,
            userIdentifier: docId
        )
    }

    func sendMessage() {
        guard !textInput.isEmpty else { return }
        HapticManager.shared.trigger(.medium)

        let textToSend = textInput
        textInput = ""

        viewModel.sendMessage(text: textToSend)
    }
}

// MARK: - Follow-up Prompt Chip

struct FollowupChip: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                    Text(text)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.blue.opacity(0.4), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}

// MARK: - Thinking Dots Animation

struct ThinkingDots: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: i))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: phase
                    )
            }
        }
        .onAppear { phase = 1.0 }
    }

    private func dotScale(for index: Int) -> CGFloat {
        phase == 0 ? 0.5 : 1.0
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Binding var text: String
    @Binding var showCamera: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            //            Button(action: { showCamera.toggle() }) {
            //                Image(systemName: "camera.fill")
            //                    .font(.system(size: 18, weight: .semibold))
            //                    .foregroundStyle(.white.opacity(0.9))
            //                    .frame(width: 44, height: 44)
            //                    .background(
            //                        ConcentricRectangle(corners: .concentric)
            //                            .foregroundStyle(.ultraThinMaterial)
            //                    )
            //                    .containerShape(Circle())
            //            }

            HStack {
                TextField("Ask Smriti...", text: $text)
                    .foregroundStyle(.primary)
                    .tint(.white)
                    .padding(.leading, 12)
                    .onSubmit(onSend)

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.gradient)
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

            Text(LocalizedStringKey(message.text))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    message.isUser
                        ? AnyShapeStyle(Color.blue.gradient)
                        : AnyShapeStyle(Color.yellow.gradient)
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
