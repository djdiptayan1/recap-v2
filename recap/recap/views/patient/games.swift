//
//  games.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct games: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(gamesDemo) { game in
                            NavigationLink(destination: destinationView(for: game)) {
                                GamesCard(game: game)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityHint("Opens \(game.name).")
                        }
                    }
                }
                .padding(AppConfig.UI.screenPadding - 10)
            }
            .standardBackground()
            .navigationTitle("Games")
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
