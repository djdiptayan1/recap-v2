//
//  citationsModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
struct citationModel: Identifiable, Codable{
    let id: String
    let title: String
    let year: String
    let authors: String
    let url: String
    let journal: String
    let doi: String
    let source: String
}

struct CitationResponse: Codable{
    let success: Bool
    let data: [citationModel]
    let count: Int
}
