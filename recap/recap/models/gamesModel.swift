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
    gamesModel(imageName: "globe.central.south.asia.fill", name: "Geo Sorter", description: "Boost memory", screenName: "GeoSorterViewController"),
    gamesModel(imageName: "brain.fill", name: "Match Mania", description: "Increase memory agility", screenName: "MemoryGameView"),
    gamesModel(imageName: "brain.head.profile", name: "Pattern Memory", description: "Remember sequences", screenName: "PatternMemoryViewController"),
    gamesModel(imageName: "house.fill", name: "Daily Objects", description: "Recall everyday items", screenName: "DailyObjectsGameView"),
]
