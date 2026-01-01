//
//  MemoryAnalyticsCard.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct MemoryAnalyticsCard: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var navigateToDetail = false
    @State private var selectedDetailType: TimeFrame?
    
    @State private var selectedDataPoint: AnalyticsData?
    
    var body: some View {
        VStack(spacing: 20) {
            
            VStack(spacing: 16) {
                HStack{
                    Text("Trends")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
//                .padding(.horizontal, 20)
                
//                // Custom Segmented Picker
//                HStack(spacing: 0) {
//                    ForEach(TimeFrame.allCases) { timeframe in
//                        Button(action: {
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                viewModel.selectedTimeFrame = timeframe
//                            }
//                        }) {
//                            Text(timeframe.rawValue)
//                                .font(.system(size: 13, weight: .semibold))
//                                .foregroundColor(viewModel.selectedTimeFrame == timeframe ? .white : AppConfig.Colors.textSecondary)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 8)
//                                .background(
//                                    ZStack {
//                                        if viewModel.selectedTimeFrame == timeframe {
//                                            Capsule()
//                                                .fill(AppConfig.Colors.accent)
//                                                .matchedGeometryEffect(id: "SEGMENT", in: animationNamespace)
//                                        }
//                                    }
//                                )
//                        }
//                    }
//                }
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
            
            // 2. The Chart Area (Interactive)
            VStack {
                ZStack {
                    switch viewModel.selectedTimeFrame {
                    case .immediate:
                        DailyPerformanceChart(data: viewModel.dailyData)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    case .recent:
                        WeeklyTrendChart(data: viewModel.weeklyData, selectedPoint: $selectedDataPoint)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    case .remote:
                        QuarterlyAverageChart(data: viewModel.quarterlyData, selectedPoint: $selectedDataPoint)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 10)
                // Tap Gesture to Navigate
                .onTapGesture {
                    selectedDetailType = viewModel.selectedTimeFrame
                    navigateToDetail = true
                }
                
                // 3. Footer / Interaction Label
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
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
        // Navigation Destination
        .navigationDestination(isPresented: $navigateToDetail) {
            if let type = selectedDetailType {
                DetailedAnalyticsView(timeFrame: type)
            }
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
