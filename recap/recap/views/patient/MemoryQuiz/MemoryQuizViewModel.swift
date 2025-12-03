//
//  MemoryQuizViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI
import Combine

class MemoryQuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion] = [
        QuizQuestion(text: "From time to time, I forget what day of the week it is."),
        QuizQuestion(text: "Sometimes when I’m looking for something, I forget what it is that I’m looking for."),
        QuizQuestion(text: "My friends and family seem to think I’m more forgetful now than I used to be."),
        QuizQuestion(text: "Sometimes I forget the names of my friends."),
        QuizQuestion(text: "It’s hard for me to add two-digit numbers without writing them down."),
        QuizQuestion(text: "I frequently miss appointments because I forget them."),
        QuizQuestion(text: "I rarely feel energetic."),
        QuizQuestion(text: "Small problems upset me more than they once did."),
        QuizQuestion(text: "It’s hard for me to concentrate for even an hour."),
        QuizQuestion(text: "I often misplace my keys, and when I find them, I often can't remember putting them there."),
        QuizQuestion(text: "I frequently repeat myself."),
        QuizQuestion(text: "Sometimes I get lost, even when I'm driving somewhere I've been before."),
        QuizQuestion(text: "Sometimes I forget the point I'm trying to make."),
        QuizQuestion(text: "To feel mentally sharp, I depend upon caffeine."),
        QuizQuestion(text: "It takes longer for me to learn things than it used to.")
    ]
    
    @Published var currentIndex = 0
    @Published var trueAnswersCount = 0
    @Published var isCompleted = false
    
    var progress: CGFloat {
        return CGFloat(currentIndex) / CGFloat(questions.count)
    }
    
    func submitAnswer(isTrue: Bool) {
        if isTrue {
            trueAnswersCount += 1
        }
        
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                isCompleted = true
            }
        }
    }
    
    func getResult() -> QuizResult {
        switch trueAnswersCount {
        case 0...8:
            return QuizResult(
                score: trueAnswersCount,
                title: "Functioning Okay",
                description: "Your brain is functioning okay. By learning to relax and maintain a healthy diet, your brain can function at even higher levels.",
                color: Color.green,
                icon: "brain.head.profile"
            )
        case 9...12:
            return QuizResult(
                score: trueAnswersCount,
                title: "Brain in Danger",
                description: "Check your diet today. You can reduce brain drain and memory loss with vitamins, brain foods, herbs, yoga and meditation.",
                color: Color.orange,
                icon: "exclamationmark.triangle.fill"
            )
        default: // 13-15
            return QuizResult(
                score: trueAnswersCount,
                title: "Running on Empty",
                description: "You should see your doctor. You can refuel your brain and prevent further memory loss with food, vitamins, herbs, exercises, and medications.",
                color: Color.red,
                icon: "battery.0.percent"
            )
        }
    }
    
    func restart() {
        currentIndex = 0
        trueAnswersCount = 0
        isCompleted = false
    }
}
