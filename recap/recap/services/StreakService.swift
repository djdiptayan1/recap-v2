//
//  StreakService.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation

struct StreakData {
    let streakDates: [String: Bool]
}

class StreakService {
    private let verifiedUserDocID: String
    
    var streakDataFetched: ((Int, Int, Int) -> Void)?
    
    init(verifiedUserDocID: String) {
        self.verifiedUserDocID = verifiedUserDocID
    }
    
    func fetchAndUpdateStreakStats() {
        // Mock implementation
        // In a real app, fetch from Firestore or UserDefaults
        let maxStreak = 5
        let currentStreak = 3
        let activeDays = 12
        
        streakDataFetched?(maxStreak, currentStreak, activeDays)
    }
    
    func getStreaksForUser(yearMonth: String, completion: @escaping (StreakData?) -> Void) {
        // Mock implementation
        // Return some random streak dates for the given month
        let mockDates = [
            "\(yearMonth)-01": true,
            "\(yearMonth)-02": true,
            "\(yearMonth)-05": true,
            "\(yearMonth)-10": true
        ]
        completion(StreakData(streakDates: mockDates))
    }
}
