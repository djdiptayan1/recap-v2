//
//  gamesModel.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation
import Foundation
struct gamesModel: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let name: String
    let description: String
    let screenName: String
}

let gamesDemo = [
    gamesModel(imageName: "text.bubble.fill", name: "Word Link", description: "Connect related words", screenName: "WordAssociationGameView"),
    gamesModel(imageName: "brain.fill", name: "Match Mania", description: "Increase memory agility", screenName: "MemoryGameView"),
    gamesModel(imageName: "number.circle.fill", name: "Number Bubbles", description: "Pop numbers in order!", screenName: "NumberBubblesGameView"),
    gamesModel(imageName: "house.fill", name: "Daily Objects", description: "Recall everyday items", screenName: "DailyObjectsGameView"),
    gamesModel(imageName: "square.grid.2x2.fill", name: "Pattern Memory", description: "Repeat visual sequences", screenName: "PatternMemoryGameView"),
]
