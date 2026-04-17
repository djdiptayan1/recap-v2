//
//  games.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct games: View {
    @StateObject private var analyticsViewModel = GameAnalyticsViewModel(
        patientId: GameSessionService.shared.currentPatientDocumentID() ?? ""
    )

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    GlassEffectContainer {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(gamesDemo) { game in
                                NavigationLink(destination: destinationView(for: game)) {
                                    GamesCard(game: game)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    GameInsightsCard(viewModel: analyticsViewModel)
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("Games")
            .task {
                await analyticsViewModel.fetch()
            }
        }
    }
}

@ViewBuilder
private func destinationView(for game: gamesModel) -> some View {
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
        VStack {
            Text("Game: \(game.name)")
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    games()
}
