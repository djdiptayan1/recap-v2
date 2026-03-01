//
//  NumberBubblesGameView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

private let bubblesAccent = AppConfig.Colors.accent

struct NumberBubblesGameView: View {
    @StateObject private var viewModel = NumberBubblesGameViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Cheerful background — app palette
            AppConfig.Colors.background
                .ignoresSafeArea()

            switch viewModel.phase {
            case .instruction:
                NumberBubblesInstructionView(onStart: viewModel.startGame)
                    .transition(.opacity)
            case .playing, .levelComplete, .gameOver:
                gameView
                    .transition(.opacity)
            }

            if viewModel.phase == .levelComplete {
                levelCompleteOverlay
            }
            if viewModel.phase == .gameOver {
                gameOverOverlay
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.phase)
        .navigationTitle("Number Bubbles")
    }

    // MARK: - Game View

    private var gameView: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack {
                // Timer
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(viewModel.timeRemaining <= 5 ? AppConfig.Colors.alert : bubblesAccent)
                    Text("\(viewModel.timeRemaining)s")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.timeRemaining <= 5 ? AppConfig.Colors.alert : AppConfig.Colors.textPrimary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)

                Spacer()

                Text("Level \(viewModel.level)")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(bubblesAccent)
                    .cornerRadius(16)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(viewModel.score)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(AppConfig.Colors.textPrimary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
            .padding(.top, 16)

            // "Tap next" hint
            HStack(spacing: 10) {
                Text("Tap next:")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                if let nextBubble = viewModel.bubbles.first(where: {
                    $0.number == viewModel.nextTarget && !$0.isPopped
                }) {
                    ZStack {
                        Circle()
                            .fill(nextBubble.color)
                            .frame(width: 44, height: 44)
                            .shadow(color: nextBubble.color.opacity(0.5), radius: 6, x: 0, y: 3)
                        Text("\(viewModel.nextTarget)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.nextTarget)
                }
            }
            .padding(.top, 14)

            // Bubble canvas
            GeometryReader { geo in
                ZStack {
                    ForEach(viewModel.bubbles) { bubble in
                        if !bubble.isPopped {
                            BubbleView(
                                bubble: bubble,
                                isWrong: viewModel.wrongTapID == bubble.id
                            )
                            .position(
                                x: bubble.posX * geo.size.width,
                                y: bubble.posY * geo.size.height
                            )
                            .onTapGesture {
                                viewModel.tapBubble(bubble)
                            }
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Level Complete Overlay

    private var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 72))
                Text("Level \(viewModel.level) Complete!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                Text("Score: \(viewModel.score)")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(bubblesAccent)
                Button(action: viewModel.nextLevel) {
                    Text("Next Level →")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(bubblesAccent)
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
                .padding(.horizontal, AppConfig.UI.screenPadding)
            }
            .padding(36)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 36)
        }
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("⏰")
                    .font(.system(size: 64))
                Text("Time's Up!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                VStack(spacing: 6) {
                    Text("Level Reached: \(viewModel.level)")
                    Text("Final Score: \(viewModel.score)")
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)

                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Exit")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .frame(width: 100, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }
                    Button(action: viewModel.restartGame) {
                        Text("Play Again")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(bubblesAccent)
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }
                }
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Bubble Circle View

private struct BubbleView: View {
    let bubble: Bubble
    let isWrong: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            isWrong ? AppConfig.Colors.alert.opacity(0.9) : bubble.color.opacity(0.85),
                            isWrong ? AppConfig.Colors.alert : bubble.color,
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 52
                    )
                )
                .frame(width: 74, height: 74)
                .shadow(
                    color: (isWrong ? AppConfig.Colors.alert : bubble.color).opacity(0.5),
                    radius: 8, x: 0, y: 4
                )
                // Gloss highlight
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 22, height: 22)
                        .offset(x: -18, y: -18)
                )

            Text("\(bubble.number)")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.12), value: isWrong)
    }
}

// MARK: - Instruction View

private struct NumberBubblesInstructionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("🔢")
                .font(.system(size: 80))
                .padding(28)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.15)))

            Text("Number Bubbles")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                NBBullet(icon: "1.circle.fill",        text: "Colourful numbered bubbles appear on screen.")
                NBBullet(icon: "2.circle.fill",        text: "Tap them in order — smallest first!")
                NBBullet(icon: "timer",                text: "Beat the clock before time runs out!")
                NBBullet(icon: "arrow.up.circle.fill", text: "Each level adds more bubbles. How far can you go?")
            }
            .padding(.horizontal, 32)

            Button(action: {
                HapticManager.shared.trigger(.selection)
                onStart()
            }) {
                Text("Start Game")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 56)
                    .background(bubblesAccent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: bubblesAccent.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .standardBackground()
    }
}

private struct NBBullet: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(bubblesAccent)
                .font(.system(size: 20, weight: .bold))
            Text(text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        NumberBubblesGameView()
    }
}
