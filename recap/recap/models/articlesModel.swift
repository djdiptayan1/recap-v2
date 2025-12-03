//
//  articlesModel.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation
import SwiftUI

struct articleModel: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let content: String
    let image: String
    let link: String
    let source: String
    let citation: String
    
    // Helper for read time
    var readTime: String {
        let words = content.split(separator: " ").count
        let mins = max(1, words / 150)
        return "\(mins) min read"
    }
}
