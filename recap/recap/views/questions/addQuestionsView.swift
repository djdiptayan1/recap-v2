//
//  addQuestionsView.swift
//  recap
//
//  Created by Diptayan Jash on 04/01/26.
//
import SwiftUI

func questionInputLabels(_ labels: String...) -> [LocalizedStringKey] {
    labels.map { LocalizedStringKey($0) }
}

struct addQuestionsView: View {
    @StateObject private var viewModel = AddQuestionsViewModel()
    @Environment(\.dismiss) var dismiss

    var patientID: String

    var body: some View {
        NavigationStack {
            ZStack {
                // 2. Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

                        // Form Components
                        VStack(spacing: 24) {
                            QuestionInputSection(
                                text: $viewModel.questionText,
                                hint: $viewModel.hint
                            )

                            CategorySelectionSection(
                                category: $viewModel.category,
                                subCategory: $viewModel.subCategory,
                                categories: viewModel.categories,
                                subCategories: viewModel.subCategories
                            )

                            OptionsInputSection(
                                options: $viewModel.answerOptions,
                                correctAnswers: $viewModel.correctAnswers,
                                onAdd: viewModel.addOption,
                                onRemove: viewModel.removeOption
                            )

                            TimingSettingsSection(
                                start: $viewModel.startTime,
                                end: $viewModel.endTime,
                                frequency: $viewModel.frequency
                            )
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)

                        // Submit Button
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            Task { await viewModel.submitQuestion(patientID: patientID) }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                                } else {
                                    Text("Save Question")
                                        .font(AppConfig.Fonts.headline)
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppConfig.Colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(AppConfig.UI.cornerRadius)
                            .shadow(
                                color: AppConfig.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.isLoading)
                        .accessibilityInputLabels(questionInputLabels("save question", "submit question", "add question"))
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add New Question")
            // Alerts
            .alert("Success", isPresented: $viewModel.isSuccess) {
                Button("Done") {
                    HapticManager.shared.trigger(.success)
                    dismiss()
                }
            } message: {
                Text("The question has been added to the daily rotation.")
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

// MARK: - Subcomponents (Breaking down complexity)

//struct HeaderView: View {
//    let title: String
//    let subtitle: String
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Text(title)
//                .font(AppConfig.Fonts.titleMedium)
//                .foregroundColor(AppConfig.Colors.textPrimary)
//
//            Text(subtitle)
//                .font(AppConfig.Fonts.body)
//                .foregroundColor(AppConfig.Colors.textSecondary)
//                .multilineTextAlignment(.center)
//        }
//    }
//}

struct QuestionInputSection: View {
    @Binding var text: String
    @Binding var hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("The Question", systemImage: "questionmark.bubble.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .textCase(.uppercase)

            TextField("e.g., What did you have for breakfast?", text: $text, axis: .vertical)
                .font(AppConfig.Fonts.body)
                .padding(16)
                //                .background(Color.white)
                .glassEffect(.clear, in: .rect)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                )
                .accessibilityLabel("Question text")
                .accessibilityInputLabels(questionInputLabels("question", "question text", "prompt"))

            Label("Hint (Optional)", systemImage: "lightbulb.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .textCase(.uppercase)
                .padding(.top, 4)

            TextField("e.g., Think about eggs...", text: $hint)
                .font(AppConfig.Fonts.body)
                .padding(16)
                //                .background(Color.white)
                .glassEffect(.clear, in: .rect)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                )
                .accessibilityLabel("Question hint")
                .accessibilityInputLabels(questionInputLabels("hint", "question hint", "help text"))
        }
    }
}

struct CategorySelectionSection: View {
    @Binding var category: String
    @Binding var subCategory: String
    let categories: [String]
    let subCategories: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Classification", systemImage: "tag.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                // Category Picker
                Menu {
                    ForEach(categories, id: \.self) { cat in
                        Button(cat) { category = cat }
                    }
                } label: {
                    HStack {
                        Text(category)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    //                    .background(Color.white)
                    .glassEffect(.clear, in: .rect)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppConfig.Colors.stroke))
                }
                .accessibilityInputLabels(questionInputLabels("category", "question category", "classification"))

                // SubCategory Picker
                Menu {
                    ForEach(subCategories, id: \.self) { sub in
                        Button(sub) { subCategory = sub }
                    }
                } label: {
                    HStack {
                        Text(subCategory)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    //                    .background(Color.white)
                    .glassEffect(.clear, in: .rect)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppConfig.Colors.stroke))
                }
                .accessibilityInputLabels(questionInputLabels("subcategory", "question subcategory", "topic"))
            }
            .foregroundColor(AppConfig.Colors.textPrimary)
        }
    }
}

struct OptionsInputSection: View {
    @Binding var options: [String]
    @Binding var correctAnswers: [String]
    let onAdd: () -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Answer Options", systemImage: "list.bullet")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: {
                    HapticManager.shared.trigger(.selection)
                    onAdd()
                }) {
                    Label("Add", systemImage: "plus")
                        .font(.caption.bold())
                        .foregroundColor(AppConfig.Colors.accent)
                }
                .accessibilityInputLabels(questionInputLabels("add option", "new option", "plus"))
            }

            ForEach(0..<options.count, id: \.self) { index in
                HStack {
                    Button(action: {
                        HapticManager.shared.trigger(.selection)
                        let option = options[index]
                        if correctAnswers.contains(option) {
                            correctAnswers.removeAll { $0 == option }
                        } else {
                            correctAnswers.append(option)
                        }
                    }) {
                        Image(
                            systemName: correctAnswers.contains(options[index])
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .foregroundColor(
                            correctAnswers.contains(options[index])
                                ? AppConfig.Colors.success : AppConfig.Colors.textSecondary
                        )
                        .font(.system(size: 22))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityInputLabels(questionInputLabels(options[index].lowercased(), "option", "answer option"))

                    TextField(
                        "Option \(index + 1)",
                        text: Binding(
                            get: { options[index] },
                            set: { newValue in
                                if let i = correctAnswers.firstIndex(of: options[index]) {
                                    correctAnswers[i] = newValue
                                }
                                options[index] = newValue
                            }
                        ))

                    if options.count > 1 {
                        Button(action: {
                            HapticManager.shared.trigger(.warning)
                            onRemove(index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(AppConfig.Colors.alert)
                        }
                        .accessibilityInputLabels(questionInputLabels("delete option", "remove option", "trash"))
                    }
                }
                .padding()
                //                .background(Color.white)
                .glassEffect(.clear, in: .rect)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                )
            }
        }
    }
}

struct TimingSettingsSection: View {
    @Binding var start: Date
    @Binding var end: Date
    @Binding var frequency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Schedule", systemImage: "clock.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                // From Time
                DatePicker("Ask from", selection: $start, displayedComponents: .hourAndMinute)
                    .padding()
                    .accessibilityInputLabels(questionInputLabels("ask from", "start time", "from time"))

                Divider()

                // To Time
                DatePicker("Ask until", selection: $end, displayedComponents: .hourAndMinute)
                    .padding()
                    .accessibilityInputLabels(questionInputLabels("ask until", "end time", "until time"))

                Divider()

                // Frequency
                HStack {
                    Text("Frequency (Days)")
                    Spacer()
                    TextField("1", text: $frequency)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                        .accessibilityInputLabels(questionInputLabels("frequency", "days", "repeat every"))
                }
                .padding()
            }
            //            .background(Color.white)
            .glassEffect(.clear, in: .rect)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
        }
    }
}

#Preview {
    addQuestionsView(patientID: "KCLKSE")
}
