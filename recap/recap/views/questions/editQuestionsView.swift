//
//  editQuestionsView.swift
//  recap
//
//  Created by Diptayan Jash on 05/01/26.
//

import SwiftUI

struct editQuestionsView: View {
    let patientID: String
    @StateObject private var viewModel = EditQuestionsViewModel()

    // Deletion State
    @State private var questionToDelete: QuestionModel?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.questions.isEmpty {
                    ProgressView()
                } else if viewModel.questions.isEmpty {
                    VStack {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Text("No questions found")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.questions) { question in
                            NavigationLink(
                                destination: QuestionDetailEditView(
                                    patientID: patientID, question: question, viewModel: viewModel)
                            ) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.text)
                                        .font(AppConfig.Fonts.bodyBold)
                                        .foregroundColor(AppConfig.Colors.textPrimary)

                                    Text(
                                        "\(question.answerOptions.count) options • \(question.subcategory)"
                                    )
                                    .font(AppConfig.Fonts.small)
                                    .foregroundColor(AppConfig.Colors.textSecondary)

                                    if let isActive = question.isActive, !isActive {
                                        Text("Inactive")
                                            .font(.caption)
                                            .foregroundColor(AppConfig.Colors.textSecondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    HapticManager.shared.trigger(.warning)
                                    questionToDelete = question
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(AppConfig.Colors.alert)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Edit Questions")
            .onAppear {
                Task {
                    await viewModel.fetchQuestions(patientID: patientID)
                }
            }
            .alert(
                "Delete Question?", isPresented: $showDeleteConfirmation,
                presenting: questionToDelete
            ) { question in
                Button("Cancel", role: .cancel) {
                    questionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteQuestion(
                            patientID: patientID, questionID: question.id)
                    }
                }
            } message: { question in
                Text(
                    "Are you sure you want to delete \"\(question.text)\"? This action cannot be undone."
                )
            }
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct QuestionDetailEditView: View {
    let patientID: String
    let question: QuestionModel
    @ObservedObject var viewModel: EditQuestionsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var questionText: String
    @State private var answerOptions: [String]
    @State private var correctAnswers: [String]
    @State private var hint: String
    @State private var isActive: Bool

    @State private var showDeleteConfirmation = false
    @State private var showOptionDeleteConfirmation = false
    @State private var optionIndexToDelete: Int?

    init(patientID: String, question: QuestionModel, viewModel: EditQuestionsViewModel) {
        self.patientID = patientID
        self.question = question
        self.viewModel = viewModel

        _questionText = State(initialValue: question.text)
        _answerOptions = State(initialValue: question.answerOptions)
        _correctAnswers = State(initialValue: question.correctAnswers ?? [])
        _hint = State(initialValue: question.hint ?? "")
        _isActive = State(initialValue: question.isActive ?? true)
    }

    var body: some View {
        Form {
            Section(header: Text("Question Details")) {
                TextField("Question Text", text: $questionText, axis: .vertical)
                    .font(AppConfig.Fonts.body)

                TextField("Hint (Optional)", text: $hint)
                    .font(AppConfig.Fonts.body)

                Toggle("Active Question", isOn: $isActive)
                    .tint(AppConfig.Colors.accent)
                    .onChange(of: isActive) { _ in
                        HapticManager.shared.trigger(.selection)
                    }
            }

            Section(
                header: Text("Answer Options"),
                footer: Text("Select the circle to mark the correct answer(s).")
            ) {
                ForEach(0..<answerOptions.count, id: \.self) { index in
                    HStack {
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            let option = answerOptions[index]
                            if correctAnswers.contains(option) {
                                correctAnswers.removeAll { $0 == option }
                            } else {
                                correctAnswers.append(option)
                            }
                        }) {
                            Image(
                                systemName: correctAnswers.contains(answerOptions[index])
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                correctAnswers.contains(answerOptions[index])
                                    ? AppConfig.Colors.success : AppConfig.Colors.textSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())

                        TextField(
                            "Option \(index + 1)",
                            text: Binding(
                                get: { answerOptions[index] },
                                set: { newValue in
                                    if let i = correctAnswers.firstIndex(of: answerOptions[index]) {
                                        correctAnswers[i] = newValue
                                    }
                                    answerOptions[index] = newValue
                                }
                            ))
                    }
                    .swipeActions(edge: .trailing) {
                        if answerOptions.count > 2 {
                            Button(role: .destructive) {
                                optionIndexToDelete = index
                                showOptionDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(AppConfig.Colors.alert)
                        }
                    }
                }
                Button("Add Option") {
                    answerOptions.append("")
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Question")
                        Spacer()
                    }
                }
                .listRowBackground(AppConfig.Colors.alert.opacity(0.1))  // Subtle background hint
                .foregroundColor(AppConfig.Colors.alert)
            }
        }
        .navigationTitle("Edit Question")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    HapticManager.shared.trigger(.selection)
                    Task {
                        await viewModel.updateQuestion(
                            patientID: patientID,
                            question: question,
                            newText: questionText,
                            newOptions: answerOptions,
                            correctAnswers: correctAnswers,
                            hint: hint,
                            isActive: isActive
                        )
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                HapticManager.shared.trigger(.success)
                dismiss()
                viewModel.isSuccess = false
            }
        }
        // Delete Question Alert
        .alert("Delete Question?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteQuestion(patientID: patientID, questionID: question.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this question? This action cannot be undone.")
        }
        // Delete Option Alert
        .alert("Delete Option?", isPresented: $showOptionDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                optionIndexToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let index = optionIndexToDelete {
                    let option = answerOptions[index]
                    correctAnswers.removeAll { $0 == option }
                    answerOptions.remove(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete this option?")
        }
    }
}
