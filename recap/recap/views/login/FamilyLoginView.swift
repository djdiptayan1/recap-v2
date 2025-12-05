//
//  FamilyLoginView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
import CryptoKit
struct FamilyLoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FamilyLoginViewModel()
    
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
                            
                            if !viewModel.isVerified {
                                // 1. The New 6-Box Input
                                OTPInputView(text: $viewModel.patientUID)
                                    .padding(.bottom, 10)

                                // 2. Verify Button
                                Button(action: viewModel.verifyPatientUID) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView().tint(.white)
                                        }
                                        Text("Verify ID")
                                            .font(AppConfig.Fonts.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(viewModel.patientUID.count == 6 ? AppConfig.Colors.accent : AppConfig.Colors.textSecondary.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(AppConfig.UI.cornerRadius)
                                    .shadow(color: viewModel.patientUID.count == 6 ? AppConfig.Colors.accent.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                                    .animation(.easeInOut, value: viewModel.patientUID)
                                }
                                .disabled(viewModel.patientUID.count < 6 || viewModel.isLoading)
                                
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
                                            viewModel.resetVerification()
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
                        .opacity(viewModel.isVerified ? 1.0 : 0.4)
                        .grayscale(viewModel.isVerified ? 0.0 : 1.0)
                        .disabled(!viewModel.isVerified || viewModel.isLoading)
                        .animation(.easeInOut, value: viewModel.isVerified)
                        
                        Spacer()
                    }
                }
                .scrollIndicators(.hidden)
            }
            .alert("Notice", isPresented: $viewModel.showAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
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
    
    
    private func signInWithGoogle() {
        Task {
            do {
                let user = try await viewModel.signInWithGoogle()
                await MainActor.run {
                    appState.currentUser = user
                }
            } catch {
                await MainActor.run {
                    viewModel.alertMessage = error.localizedDescription
                    viewModel.showAlert = true
                }
            }
        }
    }
    private func handleAppleSignInCompletion() {}
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    FamilyLoginView()
}
