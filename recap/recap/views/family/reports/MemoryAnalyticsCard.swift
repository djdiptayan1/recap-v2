//
//  MemoryAnalyticsCard.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct MemoryAnalyticsCard: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var navigateToDetail = false
    @State private var navigateToOverall = false
    @State private var selectedDetailType: TimeFrame?
    @State private var refreshTrigger = 0
    
    @State private var selectedDataPoint: AnalyticsData?
    
    init() {
        let patientId = KeychainManager.shared.getString(key: .patientDocumentID) ?? ""
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(patientId: patientId))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            VStack(spacing: 16) {
                // Tappable header for overall analytics
                HStack {
                    Text("Trends")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Spacer()

                    Button(action: {
                        HapticManager.shared.trigger(.selection)
                        refreshTrigger += 1
                        viewModel.fetchAnalytics(forceRefresh: true)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                            .symbolEffect(
                                .rotate.clockwise.byLayer,
                                options: .nonRepeating,
                                value: refreshTrigger
                            )
                    }
                    Button(action: {
                        HapticManager.shared.trigger(.selection)
                        navigateToOverall = true
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.trigger(.selection)
                    navigateToOverall = true
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Picker("Timeframe", selection: $viewModel.selectedTimeFrame) {
                    ForEach(TimeFrame.allCases) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppConfig.Colors.accent)
                .padding(5)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
                .padding(.horizontal, 20)
            }
            
            // Decline Alert Banner
            if let alert = viewModel.declineAlert, alert.detected {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text(alert.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(12)
                .background(AppConfig.Colors.alert)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // The Chart Area
            VStack {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView("Loading analytics...")
                            .frame(height: 220)
                    } else if viewModel.dailyData.isEmpty && viewModel.weeklyData.isEmpty && viewModel.monthlyData.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                            Text("No data available yet")
                                .font(AppConfig.Fonts.small)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                        .frame(height: 220)
                    } else {
                        switch viewModel.selectedTimeFrame {
                        case .immediate:
                            DailyPerformanceChart(data: viewModel.dailyData)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        case .recent:
                            WeeklyTrendChart(data: viewModel.weeklyData, selectedPoint: $selectedDataPoint)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        case .remote:
                            QuarterlyAverageChart(data: viewModel.monthlyData, selectedPoint: $selectedDataPoint)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 10)
                .onTapGesture {
                    selectedDetailType = viewModel.selectedTimeFrame
                    navigateToDetail = true
                }
                
                // Footer / Interaction Label
                HStack {
                    if let selected = selectedDataPoint {
                        Text("\(selected.label): \(Int(selected.value)) Score")
                            .font(.caption.bold())
                            .foregroundColor(AppConfig.Colors.accent)
                            .transition(.scale)
                    } else {
                        Text("Tap chart for details")
                            .font(.caption)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .transition(.opacity)
                    }
                }
                .frame(height: 20)
            }
            .padding(.bottom, 20)
        }
//        .background(Color.white)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(AppConfig.UI.cornerRadius)
//        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
        .navigationDestination(isPresented: $navigateToDetail) {
            if let type = selectedDetailType {
                DetailedAnalyticsView(timeFrame: type, viewModel: viewModel)
            }
        }
        .navigationDestination(isPresented: $navigateToOverall) {
            OverallAnalyticsView(viewModel: viewModel)
        }
    }
    
    @Namespace private var animationNamespace
}


#Preview {
    NavigationStack {
        ZStack {
            ScrollView {
                MemoryAnalyticsCard()
                    .padding()
            }
        }
        .standardBackground()
    }
}
