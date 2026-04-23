//
//  OnboardingFlowView.swift
//  recap
//

import SwiftUI
import UserNotifications

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentStep = 0
    @State private var selectedGoals: Set<String> = []
    @State private var selectedSupportStyle: String?
    @State private var notificationsEnabled = false
    @State private var isRequestingNotifications = false
    @State private var availabilityPrompt: FoundationAvailabilityPrompt?
    @State private var aiModeSummary = "Checking AI mode..."
    @State private var isResolvingAIState = true

    private var currentUser: patientModel? { appState.currentUser }
    private var isPatient: Bool { currentUser?.type == "patient" }

    private var goalOptions: [OnboardingChoice] {
        if isPatient {
            return [
                .init(title: "Stay on routine", subtitle: "Keep daily tasks clear and predictable."),
                .init(title: "Remember moments", subtitle: "Capture memories and revisit them easily."),
                .init(title: "Feel less confused", subtitle: "Get calm, simple guidance when things feel off."),
                .init(title: "Keep close to family", subtitle: "Reach loved ones faster and share progress."),
            ]
        }

        return [
            .init(title: "Track routines", subtitle: "Keep medication, meals, and day structure consistent."),
            .init(title: "Spot changes early", subtitle: "Notice drift before it becomes a crisis."),
            .init(title: "Build memory prompts", subtitle: "Give Smriti real family context to use."),
            .init(title: "Coordinate care", subtitle: "Make updates easier for family and caretakers."),
        ]
    }

    private var supportStyles: [OnboardingChoice] {
        if isPatient {
            return [
                .init(title: "Gentle and simple", subtitle: "Short prompts with clear next steps."),
                .init(title: "Voice-friendly", subtitle: "Use Recap with less typing and more talking."),
                .init(title: "Step by step", subtitle: "Break tasks into one thing at a time."),
            ]
        }

        return [
            .init(title: "Quick overview", subtitle: "See the signal fast and take action."),
            .init(title: "Detailed insights", subtitle: "Use trends and session data to guide care."),
            .init(title: "Prompt me proactively", subtitle: "Let Recap suggest what to do next."),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $currentStep) {
                introStep.tag(0)
                goalsStep.tag(1)
                supportStyleStep.tag(2)
                permissionsStep.tag(3)
                summaryStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            footer
        }
        .standardBackground()
        .task {
            await resolveProviderSummary()
            await refreshNotificationState()
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(AppConfig.Colors.stroke)
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(AppConfig.Colors.accent)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(stepTitle)
                        .font(AppConfig.Fonts.titleMedium)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stepSubtitle)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    private var introStep: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConfig.Colors.accent.opacity(0.16))
                    .frame(width: 170, height: 170)

                Image(systemName: isPatient ? "heart.text.square.fill" : "person.2.badge.gearshape.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(AppConfig.Colors.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(isPatient ? "Let Recap feel calm from day one." : "Set Recap up around your care.")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(isPatient
                     ? "We’ll tailor reminders, support style, and Smriti so the app feels simple and reassuring."
                     : "We’ll tailor reminders, insights, and Smriti so your family gets useful signal without extra noise.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }

            onboardingHighlight(
                title: isPatient ? "What you’ll get" : "What you’ll unlock",
                bullets: isPatient
                    ? ["A simpler daily rhythm", "More confidence using the app", "Support that matches your pace"]
                    : ["A clearer daily dashboard", "Better context for Smriti", "Trends that matter to care"]
            )

            Spacer()
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var goalsStep: some View {
        VStack(spacing: 18) {
            ForEach(goalOptions) { option in
                SelectableChoiceCard(
                    title: option.title,
                    subtitle: option.subtitle,
                    isSelected: selectedGoals.contains(option.title),
                    isMultiSelect: true
                ) {
                    if selectedGoals.contains(option.title) {
                        selectedGoals.remove(option.title)
                    } else {
                        selectedGoals.insert(option.title)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var supportStyleStep: some View {
        VStack(spacing: 18) {
            ForEach(supportStyles) { option in
                SelectableChoiceCard(
                    title: option.title,
                    subtitle: option.subtitle,
                    isSelected: selectedSupportStyle == option.title,
                    isMultiSelect: false
                ) {
                    selectedSupportStyle = option.title
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var permissionsStep: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notifications")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Text(isPatient
                     ? "Turn reminders on so Recap can keep the day moving without needing family to repeat everything."
                     : "Turn reminders on so you can help keep routines consistent and catch missed moments faster.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                Button(action: requestNotificationPermission) {
                    HStack {
                        if isRequestingNotifications {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(notificationsEnabled ? "Notifications Enabled" : "Enable Notifications")
                            .font(AppConfig.Fonts.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(notificationsEnabled ? AppConfig.Colors.success : AppConfig.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
                .disabled(isRequestingNotifications || notificationsEnabled)
            }
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))

            VStack(alignment: .leading, spacing: 12) {
                Text("AI Mode")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                if isResolvingAIState {
                    ProgressView()
                        .tint(AppConfig.Colors.accent)
                } else {
                    Text(aiModeSummary)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }

                if let availabilityPrompt {
                    Text(availabilityPrompt.message)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))

            Spacer()
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var summaryStep: some View {
        VStack(spacing: 18) {
            onboardingHighlight(
                title: "Your Recap setup",
                bullets: [
                    "Focus: \(selectedGoals.isEmpty ? "Balanced support" : selectedGoals.sorted().joined(separator: ", "))",
                    "Style: \(selectedSupportStyle ?? "Gentle guidance")",
                    "Notifications: \(notificationsEnabled ? "On" : "You can enable them later")",
                    "AI: \(aiModeSummary)",
                ]
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(isPatient ? "What happens next" : "Your first best actions")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Text(isPatient
                     ? "Start with Today, answer one question, and try a short game. Smriti will adapt to the support style you picked."
                     : "Start by checking Trends, adding the first reminders, and building a few memory details for Smriti to use.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))

            Spacer()
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
    }

    private var footer: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(AppConfig.Colors.textSecondary)
            }

            Spacer()

            Button(action: handlePrimaryAction) {
                Text(currentStep == 4 ? "Start Using Recap" : "Continue")
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(.white)
                    .frame(width: currentStep == 4 ? 210 : 140, height: 54)
                    .background(canProceed ? AppConfig.Colors.accent : AppConfig.Colors.textSecondary.opacity(0.35))
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, AppConfig.UI.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 28)
    }

    private var progress: CGFloat {
        CGFloat(currentStep + 1) / 5.0
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return isPatient ? "Welcome" : "Care Setup"
        case 1: return isPatient ? "What matters most?" : "What matters most?"
        case 2: return isPatient ? "How should Recap help?" : "How should Recap guide you?"
        case 3: return "Helpful permissions"
        default: return "Ready to begin"
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return isPatient ? "A calmer first-run experience for memory care." : "Tailor Recap around your caregiving workflow."
        case 1: return "Pick the outcomes Recap should prioritize first."
        case 2: return "Choose the tone and pacing Recap should use."
        case 3: return "Prime reminders and explain how AI will work on this device."
        default: return "This setup can be changed later."
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !selectedGoals.isEmpty
        case 2:
            return selectedSupportStyle != nil
        default:
            return true
        }
    }

    private func handlePrimaryAction() {
        guard canProceed else { return }

        if currentStep < 4 {
            withAnimation {
                currentStep += 1
            }
            return
        }

        guard let user = currentUser else { return }

        let profile = OnboardingProfile(
            role: user.type ?? "unknown",
            goals: selectedGoals.sorted(),
            supportStyle: selectedSupportStyle ?? "Gentle guidance",
            wantsNotifications: notificationsEnabled,
            aiModeSummary: aiModeSummary,
            completedAt: Date()
        )
        appState.completeOnboarding(profile: profile)
    }

    private func requestNotificationPermission() {
        isRequestingNotifications = true
        NotificationManager.shared.requestAuthorization { granted, _ in
            notificationsEnabled = granted
            isRequestingNotifications = false
        }
    }

    private func refreshNotificationState() async {
        await withCheckedContinuation { continuation in
            NotificationManager.shared.getNotificationSettings { settings in
                notificationsEnabled = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral
                continuation.resume()
            }
        }
    }

    private func resolveProviderSummary() async {
        isResolvingAIState = true
        let decision = await FoundationAvailabilityService.shared.resolveProvider()
        availabilityPrompt = decision.prompt
        switch decision.provider {
        case .foundation:
            aiModeSummary =
                "This device can use the on-device Foundation Model for Smriti when Apple Intelligence is ready."
        case .gemini:
            aiModeSummary =
                "This device will use the Gemini-based Smriti fallback because on-device Foundation Models are not available here."
        }
        isResolvingAIState = false
    }

    @ViewBuilder
    private func onboardingHighlight(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            ForEach(bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppConfig.Colors.accent)
                        .padding(.top, 2)
                            .accessibilityHidden(true)

                    Text(bullet)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
    }
}

private struct OnboardingChoice: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

private struct SelectableChoiceCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isMultiSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppConfig.Colors.accent : AppConfig.Colors.card)
                        .frame(width: 28, height: 28)

                    Image(systemName: isMultiSelect ? (isSelected ? "checkmark" : "plus") : (isSelected ? "circle.inset.filled" : "circle"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppConfig.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(18)
            .background(AppConfig.Colors.card.opacity(isSelected ? 0.98 : 0.92))
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(isSelected ? AppConfig.Colors.accent : AppConfig.Colors.stroke, lineWidth: 1.5)
            )
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(subtitle)
        .accessibilityInputLabels([title.lowercased(), isMultiSelect ? "option" : "choice", "onboarding"])
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject({
            let state = AppState()
            state.currentUser = patientModel(
                firstName: "Meera",
                lastName: "Sen",
                patientUID: "ABC123",
                dateOfBirth: "1945-07-01",
                sex: "Female",
                bloodGroup: "O+",
                stage: "Early",
                profileImageURL: nil,
                email: "meera@example.com",
                id: "preview-user",
                type: "patient",
                familyMembers: []
            )
            state.needsOnboarding = true
            return state
        }())
}
