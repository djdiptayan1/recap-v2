//
//  OTPInputView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct OTPInputView: View {
    @Binding var text: String
    let length: Int = 6
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .center) {
            
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: isActive(index) ? AppConfig.Colors.accent.opacity(0.3) : Color.black.opacity(0.05),
                                    radius: isActive(index) ? 8 : 4,
                                    x: 0,
                                    y: 4)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor(for: index), lineWidth: isActive(index) ? 2 : 1)
                        
                        Text(getChar(at: index))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textPrimary)
                    }
                    .frame(width: 48, height: 56) // Fixed size for boxes
                    .animation(.easeInOut(duration: 0.1), value: text)
                }
            }
            .accessibilityHidden(true)
            
            TextField("", text: $text)
                .focused($isFocused)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .textContentType(.oneTimeCode)
                .submitLabel(.done)
                .accentColor(.clear)
                .foregroundColor(.clear)
                .frame(width: 340, height: 56)
                .accessibilityLabel("One-time code")
                .accessibilityValue(text.isEmpty ? "No digits entered" : "\(text.count) of \(length) digits entered")
                .accessibilityHint("Enter the verification code sent to your device")
                .accessibilityInputLabels(["one-time code", "verification code", "code", "otp"])
                .onAppear {
                    DispatchQueue.main.async {
                        isFocused = true
                    }
                }
                .onChange(of: text) { oldValue, newValue in
                    var adjusted = newValue.uppercased()
                    if adjusted.count > length {
                        adjusted = String(adjusted.prefix(length))
                    }
                    if adjusted != text {
                        text = adjusted
                    }
                }
        }
    }
    
    
    private func getChar(at index: Int) -> String {
        if index < text.count {
            let i = text.index(text.startIndex, offsetBy: index)
            return String(text[i])
        }
        return ""
    }
    
    private func isActive(_ index: Int) -> Bool {
        return isFocused && (index == text.count || (index == length - 1 && text.count == length))
    }
    
    private func borderColor(for index: Int) -> Color {
        if isActive(index) {
            return AppConfig.Colors.accent
        } else {
            return AppConfig.Colors.stroke
        }
    }
}

//#Preview {
//    OTPInputView(text: Binding<String>)
//}
