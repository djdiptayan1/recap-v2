//
//  appConfig.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation
import SwiftUI

struct AppConfig {
    
    /// UI constants
    struct UI {
        static let cornerRadius: CGFloat = 18
        static let buttonCornerRadius: CGFloat = 14
        static let cardShadowRadius: CGFloat = 4
        static let cardShadowOffsetY: CGFloat = 2
        static let padding: CGFloat = 16
        static let screenPadding: CGFloat = 24
        static let spacing: CGFloat = 12
    }
    
    struct Colors {
        static let background = Color("AppBackground")
        static let card = Color("CardBackground")
        static let textPrimary = Color("PrimaryText")
        static let textSecondary = Color("SecondaryText")
        static let accent = Color("Accent")
        static let alert = Color("Alert")
        static let success = Color("Success")
        static let stroke = Color("Stroke")
        
        static let bg_teal = Color("bg_teal")
        static let bg_pink = Color("bg_pink")
    }
    
//    | Name           | Light (Hex) | Dark (Hex) |
//    | -------------- | ----------- | ---------- |
//    | AppBackground  | `#F9FAF7`   | `#0B0B0B`  |
//    | CardBackground | `#FFFFFF`   | `#1A1A1A`  |
//    | PrimaryText    | `#0E2A47`   | `#D6E6F5`  |
//    | SecondaryText  | `#5A6777`   | `#AEB8C2`  |
//    | Accent         | `#8DD3BB`   | `#6AB89B`  |
//    | Alert          | `#E86C6C`   | `#FF9A9A`  |
//    | Success        | `#A8E063`   | `#83C94B`  |
//    | Stroke         | `#E2E8EC`   | `#2C2C2C`  |
    
    struct Fonts {
        static let titleLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let titleMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 18, weight: .regular, design: .rounded)
        static let bodyBold = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let small = Font.system(size: 14, weight: .regular, design: .rounded)
    }

    struct ApiEndpoints{
//        static let baseURL = "http://localhost:3000/api/" //-> USE WHEN USING SIMULATOR
        static let baseURL = "http://192.168.1.2:3000/api/"  //-> USE WHEN USING REAL PHONE
//        static let baseURL = "https://recap-v2.vercel.app/api/"  //-> PRODUCTION
        static let articles = "articles"
        static let citations = "citations"
        static let memoryQuiz = "memoryquiz"
        //streaks
        static let streaks = "streaks"
        static let streakStats = "streaks/stats"
        static let streakYear = "streaks/year"
        static let streakMonth = "streaks/month"
        
        //family members
        static let familyMembers = "familymembers"
        
        //auth
        static let verifyUID = "auth/verify-uid"
        static let veryfyFamily = "auth/verify-familymember"
        static let createFamilyUser = "auth/create-family-user"
        static let verifyFamilyMember = "auth/verify-familymember"
        static let patientSignupCompletion = "auth/patientsignup"
        static let familySignupCompletion = "auth/familysignup"
        
        //questions
        static let getAllQuestions = "questions"
        static let getDailyQuestions = "questions/dailyquestions"
        static let familyQuestions = "questions/family"
    }

    struct FirebaseCollections{
        static let users = "users"
    }
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255,
            opacity: Double(a) / 255)
    }
}

extension View {
    func standardBackground() -> some View {
        self.background(AppBackground())
    }
}
