//
//  AestheticInput.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct AestheticInput: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var showToggle: Bool = false
    @Binding var isPasswordVisible: Bool
    
    // Derived binding to handle the secure toggle logic
    private var shouldShowSecure: Bool {
        return isSecure && !isPasswordVisible
    }

    private var fieldInputLabels: [LocalizedStringKey] {
        var labels: [LocalizedStringKey] = [LocalizedStringKey(placeholder)]
        let lowercasedPlaceholder = placeholder.lowercased()

        if lowercasedPlaceholder.contains("email") {
            labels.append(contentsOf: ["email", "email address"])
        }
        if lowercasedPlaceholder.contains("password") {
            labels.append(contentsOf: ["password", "passcode"])
        }
        if lowercasedPlaceholder.contains("first name") {
            labels.append(contentsOf: ["first name", "given name"])
        }
        if lowercasedPlaceholder.contains("last name") {
            labels.append(contentsOf: ["last name", "surname"])
        }
        if lowercasedPlaceholder.contains("confirm") {
            labels.append(contentsOf: ["confirm password", "repeat password"])
        }

        return labels
    }

    private var toggleInputLabels: [LocalizedStringKey] {
        isPasswordVisible
            ? ["hide password", "password visibility"]
            : ["show password", "password visibility"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon Bubble
                ZStack {
                    Circle()
                        .fill(AppConfig.Colors.accent.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppConfig.Colors.accent)
                }
                .accessibilityHidden(true)

                // Input Field
                Group {
                    if shouldShowSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityLabel(placeholder)
                .accessibilityHint(isSecure ? "Secure text field" : "Text field")
                .accessibilityInputLabels(fieldInputLabels)

                // Password Toggle Eye
                if showToggle {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    .accessibilityHint("Toggles whether the password is visible")
                    .accessibilityInputLabels(toggleInputLabels)
                }
            }
            .padding(12)
//            .background(Color.white) // Clean white background
            .glassEffect(.clear, in: .rect)
            .cornerRadius(AppConfig.UI.cornerRadius)
            // Soft Shadow + Border
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
        }
    }
}
