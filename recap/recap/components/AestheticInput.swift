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

                // Password Toggle Eye
                if showToggle {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
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
