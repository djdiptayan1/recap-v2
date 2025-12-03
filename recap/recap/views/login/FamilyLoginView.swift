//
//  FamilyLoginView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
import CryptoKit
struct FamilyLoginView: View {
    
    @State private var patientUID = ""
    @State private var isVerified = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        
                        VStack(spacing: 16) {
                            Image("recapLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 15, x: 0, y: 10)
                            
                            VStack(spacing: 6) {
                                Text("Family Access")
                                    .font(AppConfig.Fonts.titleLarge)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                
                                Text("Enter the unique ID shared by the patient")
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                        
                        VStack(spacing: 30) {
                            
                            if !isVerified {
                                // 1. The New 6-Box Input
                                OTPInputView(text: $patientUID)
                                    .padding(.bottom, 10)

                                // 2. Verify Button
                                Button(action: verifyPatientUID) {
                                    HStack {
                                        if isLoading {
                                            ProgressView().tint(.white)
                                        }
                                        Text("Verify ID")
                                            .font(AppConfig.Fonts.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(patientUID.count == 6 ? AppConfig.Colors.accent : AppConfig.Colors.textSecondary.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(AppConfig.UI.cornerRadius)
                                    .shadow(color: patientUID.count == 6 ? AppConfig.Colors.accent.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                                    .animation(.easeInOut, value: patientUID)
                                }
                                .disabled(patientUID.count < 6 || isLoading)
                                
                            } else {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(AppConfig.Colors.success.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppConfig.Colors.success)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ID Verified")
                                            .font(AppConfig.Fonts.bodyBold)
                                            .foregroundColor(AppConfig.Colors.textPrimary)
                                        Text("Patient found successfully")
                                            .font(AppConfig.Fonts.small)
                                            .foregroundColor(AppConfig.Colors.textSecondary)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            isVerified = false
                                            patientUID = ""
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(AppConfig.UI.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                                        .stroke(AppConfig.Colors.success.opacity(0.5), lineWidth: 1)
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        
                        
                        // --- Sign In Options (Locked/Unlocked) ---
                        VStack(spacing: 24) {
                            HStack {
                                Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
                                Text("then sign in with")
                                    .font(AppConfig.Fonts.small)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                                Rectangle().fill(AppConfig.Colors.stroke).frame(height: 1)
                            }
                            .padding(.top, 30)
                            
                            VStack(spacing: 16) {
                                Button(action: signInWithGoogle) {
                                    HStack {
                                        Image("google")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        Text("Sign in with Google")
                                            .font(AppConfig.Fonts.bodyBold)
                                            .foregroundColor(AppConfig.Colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(AppConfig.UI.cornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                                            .stroke(AppConfig.Colors.stroke, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                }
                                
                                // Apple Button placeholder (Ensure you have the import for this)
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 56)
                                    .cornerRadius(AppConfig.UI.cornerRadius)
                                    .overlay(Text("Sign in with Apple").foregroundColor(.white).bold())
                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        .opacity(isVerified ? 1.0 : 0.4)
                        .grayscale(isVerified ? 0.0 : 1.0)
                        .disabled(!isVerified || isLoading)
                        .animation(.easeInOut, value: isVerified)
                        
                        Spacer()
                    }
                }
                .scrollIndicators(.hidden)
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
            .standardBackground()
        }
    }
    
    
    private func verifyPatientUID() {
    }
    
    private func signInWithGoogle() {}
    private func handleAppleSignInCompletion() {}
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    FamilyLoginView()
}
