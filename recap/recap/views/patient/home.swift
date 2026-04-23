//
//  home.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct home: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var reminderViewModel = ReminderViewModel()
    @StateObject private var familyViewModel = FamilyViewModel(documentID: "")
    @StateObject private var moodViewModel = DailyMoodViewModel()
    @State private var showProfile = false
    @State private var showMoodSheet = false

    private var patientId: String {
        KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?.id ?? ""
    }

    private var nextReminder: Reminder? {
        reminderViewModel.reminders
            .compactMap { reminder -> (Reminder, Date)? in
                guard let next = reminder.nextOccurrence(after: Date()) else { return nil }
                return (reminder, next)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    private var currentStreakDays: Int {
        UserDefaults.standard.object(forKey: "currentStreakDays") as? Int ?? 0
    }

    private var recommendedGame: gamesModel {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return gamesDemo[(dayIndex - 1) % gamesDemo.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    todayOverviewCard
                    streakSection
                    memoryMoodSection
                    brainExerciseSection
                    readingSection
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("Today")
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: remindersView(viewModel: reminderViewModel)) {
//                        Image(systemName: "bell.badge.waveform.fill")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundColor(AppConfig.Colors.alert)
//                    }
//                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile.toggle()
                    } label: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                    .accessibilityLabel("Open profile")
                    .accessibilityHint("Shows your profile and account settings")
                    .accessibilityInputLabels(["profile", "account", "settings"])
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMoodSheet) {
                NavigationStack {
                    DailyMoodSheet(patientId: patientId, viewModel: moodViewModel)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                if let uid = appState.currentUser?.id {
                    familyViewModel.updateDocumentID(uid)
                    Task {
                        await familyViewModel.fetchFamilyMembers()
                        if !patientId.isEmpty {
                            await reminderViewModel.fetchReminders(
                                patientId: patientId,
                                forceRefresh: true
                            )
                            await moodViewModel.refresh(patientId: patientId)
                        }
                    }
                }
            }
        }
    }

    private var todayOverviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
//            HStack(alignment: .top) {
//                VStack(alignment: .leading, spacing: 6) {
//                    Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
//                        .font(AppConfig.Fonts.small)
//                        .foregroundColor(AppConfig.Colors.textSecondary)
//
//                    Text("A clear plan for today")
//                        .font(AppConfig.Fonts.titleMedium)
//                        .foregroundColor(AppConfig.Colors.textPrimary)
//                }
//
//                Spacer()
//
//                streakBadge
//            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Next up")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                if let nextReminder {
                    Text(nextReminder.title)
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text(
                        "\(nextReminder.category.rawValue) at \(nextReminder.time.formatted(date: .omitted, time: .shortened))"
                    )
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                } else {
                    Text("No reminder due right now")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text("The next step can be a question, a short journal note, or a game.")
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }

            HStack(spacing: 12) {
                NavigationLink(destination: questionDestination) {
                    Text("Today’s Question")
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppConfig.Colors.accent)
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
                    .accessibilityLabel("Open today's question")
                    .accessibilityHint("Opens today's question flow")
                    .accessibilityInputLabels(["open today's question", "open question", "today's question", "question"])

                NavigationLink(destination: remindersView(viewModel: reminderViewModel)) {
                    Text("Reminders")
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .frame(width: 118, height: 52)
                        .background(AppConfig.Colors.card)
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConfig.UI.buttonCornerRadius)
                                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Open reminders")
                .accessibilityHint("Opens your reminders list")
                .accessibilityInputLabels(["open reminders", "open reminder", "reminders", "reminder"])
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
        .shadow(color: AppConfig.Colors.accent.opacity(0.15), radius: 14, x: 0, y: 8)
    }

//    private var streakBadge: some View {
//        HStack(spacing: 8) {
//            Image(systemName: "flame.fill")
//                .foregroundColor(.orange)
//            Text("\(currentStreakDays)")
//                .font(AppConfig.Fonts.bodyBold)
//                .foregroundColor(AppConfig.Colors.textPrimary)
//        }
//        .padding(.horizontal, 14)
//        .padding(.vertical, 10)
//        .glassEffect(.regular.tint(.orange.opacity(0.22)), in: .capsule)
//    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 14) {
//            sectionHeader(
//                title: "Keep the streak going",
//                subtitle: streakSubtitle
//            )

            StreaksCard()
        }
    }

    private var memoryMoodSection: some View {
        let moodPalette = moodViewModel.todayEntry?.moodKey.palette ?? DailyMoodKey.neutral.palette

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    HapticManager.shared.trigger(.selection)
                    showMoodSheet = true
                } label: {
                    todayMoodCard
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log today's mood")
                .accessibilityHint("Opens the mood check-in screen")
                .accessibilityInputLabels(["mood", "log mood", "check in", "how am I feeling"])
            }
            .padding(18)
//            .background(
//                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
//                    .fill(
//                        LinearGradient(
//                            colors: [
//                                moodPalette.backgroundTop.opacity(0.42),
//                                moodPalette.backgroundBottom.opacity(0.30),
//                            ],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .overlay(
//                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
//                            .stroke(.white.opacity(0.26), lineWidth: 1)
//                    )
//            )
            .glassEffect(.clear.tint(moodPalette.primary.opacity(0.6)),
                in: .rect(cornerRadius: AppConfig.UI.cornerRadius)
            )
        }
    }

    private var todayMoodCard: some View {
        let entry = moodViewModel.todayEntry
        let mood = entry?.moodKey
        let palette = mood?.palette ?? DailyMoodKey.neutral.palette

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How does today feel?")
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(Color.black)
  
                    Text(entry == nil ? "Tap to log today's mood in one step." : entry?.shortLoggedTime ?? "Logged today")
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(Color.black)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
            }

            HStack(spacing: 14) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                palette.glow.opacity(0.95),
                                palette.primary.opacity(0.72),
                                palette.secondary.opacity(0.35),
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 30
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.9), lineWidth: 1)
                    )
                    .shadow(color: palette.primary.opacity(0.28), radius: 10, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry?.label ?? "No mood logged yet")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.black)

                    Text(
                        mood?.summaryCopy
                            ?? "Logging a quick mood helps your family understand how today is going."
                    )
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(Color.black)
                    .lineLimit(2)
                }
            }
            .padding(16)
        }
    }

    private var brainExerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
//            sectionHeader(
//                title: "Brain Exercise",
//                subtitle: "One focused game for today. The recommendation rotates each day."
//            )

            NavigationLink(destination: recommendedGameDestination(for: recommendedGame)) {
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Today’s game")
                                .font(AppConfig.Fonts.small)
                                .foregroundColor(AppConfig.Colors.textSecondary)

                            Text(recommendedGame.name)
                                .font(AppConfig.Fonts.titleMedium)
                                .foregroundColor(AppConfig.Colors.textPrimary)

                            Text(recommendedGame.description)
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: recommendedGame.imageName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                    .padding(20)

                    Divider()
                        .background(AppConfig.Colors.stroke)
                        .padding(.horizontal, 20)

//                    HStack {
//                        Text("Open today’s pick")
//                            .font(AppConfig.Fonts.bodyBold)
//                            .foregroundColor(AppConfig.Colors.textPrimary)
//
//                        Spacer()
//
//                        Text("Play now")
//                            .font(AppConfig.Fonts.bodyBold)
//                            .foregroundColor(AppConfig.Colors.accent)
//                    }
//                    .padding(20)
                }
                .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open today's game")
            .accessibilityHint("Opens the recommended game for today")
            .accessibilityInputLabels(["open today's game", "open game", "today's game", "play game"])
        }
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Read & Reflect",
                subtitle: "Articles stay close by so the day still has a calm reading space."
            )

            LetsReadCard()
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)

            Text(subtitle)
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakSubtitle: String {
        if currentStreakDays <= 0 {
            return "A small action today is enough to begin a new run."
        }
        if currentStreakDays == 1 {
            return "One day in a row. Keep the momentum alive today."
        }
        return "\(currentStreakDays) days in a row. A little consistency is building."
    }

    @ViewBuilder
    private func recommendedGameDestination(for game: gamesModel) -> some View {
        if game.screenName == "DailyObjectsGameView" {
            DailyObjectsGameView()
        } else if game.screenName == "MemoryGameView" {
            MemoryGameView()
        } else if game.screenName == "WordAssociationGameView" {
            WordAssociationGameView()
        } else if game.screenName == "NumberBubblesGameView" {
            NumberBubblesGameView()
        } else if game.screenName == "PatternMemoryGameView" {
            PatternMemoryGameView()
        } else {
            games()
        }
    }

    @ViewBuilder
    private var questionDestination: some View {
        if let id = appState.currentUser?.id {
            DailyQuestionsView(patientId: id)
                .environmentObject(appState)
        }
    }
}

#Preview {
    home()
}
