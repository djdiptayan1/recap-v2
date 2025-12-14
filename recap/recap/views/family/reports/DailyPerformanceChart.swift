//
//  DailyPerformanceChart.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct DailyPerformanceChart: View {
    let data: [AnalyticsData]
    
    // Track selection
    @State private var selectedSegmentID: UUID?
    
    // Internal Model for the Pie
    private struct ChartSegment: Identifiable {
        let id = UUID()
        let type: String
        let value: Double
        let color: Color
    }
    
    // Transform incoming data into ChartSegments
    private var segments: [ChartSegment] {
        var segments: [ChartSegment] = []
        
        // Extract Correct
        if let correctItem = data.first(where: { $0.label == "Correct" }) {
            segments.append(ChartSegment(type: "Correct", value: correctItem.value, color: AppConfig.Colors.success))
        }
        
        // Extract Incorrect
        if let wrongItem = data.first(where: { $0.label == "Incorrect" }) {
            segments.append(ChartSegment(type: "Incorrect", value: wrongItem.value, color: AppConfig.Colors.alert))
        }
        
        return segments
    }
    
    private var totalValue: Double {
        segments.map(\.value).reduce(0, +)
    }
    
    var body: some View {
        ZStack {
            // 1. The Interactive Chart
            Chart(segments) { segment in
                SectorMark(
                    angle: .value("Count", segment.value),
                    innerRadius: .ratio(0.65), // Donut Style
                    outerRadius: selectedSegmentID == segment.id ? .ratio(1.0) : .ratio(0.9), // Pop effect
                    angularInset: 2.0 // Modern gap between slices
                )
                .cornerRadius(6) // Rounded corners on slices
                .foregroundStyle(segment.color.gradient) // Subtle gradient for depth
                .shadow(color: segment.color.opacity(0.3), radius: selectedSegmentID == segment.id ? 4 : 0)
            }
            .chartLegend(.hidden) // Hiding legend as requested
            .chartBackground { proxy in
                // Interaction Layer
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    handleTap(at: value.location, in: geo.frame(in: .local), proxy: proxy)
                                }
                        )
                }
            }
            
            // 2. Center Info Display
            VStack(spacing: 2) {
                if let selectedID = selectedSegmentID,
                   let selectedSegment = segments.first(where: { $0.id == selectedID }) {
                    
                    // Selected State
                    Text("\(Int(selectedSegment.value))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text(selectedSegment.type)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                    
                    // Percentage Badge
                    Text("\(Int((selectedSegment.value / totalValue) * 100))%")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedSegment.color)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                        .transition(.scale.combined(with: .opacity))
                    
                } else {
                    // Default State (Total)
                    Text("\(Int(totalValue))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppConfig.Colors.textPrimary)
                    
                    Text("Total")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            .animation(.spring(response: 0.3), value: selectedSegmentID)
        }
        .padding()
    }
    
    // MARK: - Tap Logic
    private func handleTap(at location: CGPoint, in rect: CGRect, proxy: ChartProxy) {
        // Calculate the angle of the tap relative to the center
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        // Calculate angle in degrees (SwiftUI Charts start at 12 o'clock, which is -90 degrees in standard math)
        // We map the tap angle to the accumulated values of the segments
        
        // Haptics
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Simple Toggle Logic for UX
        // If we have data, we just cycle through them on tap if exact angle math is overkill,
        // but let's try to be smart. Since getting exact SectorMark bounds from proxy is hard in SwiftUI currently:
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            if selectedSegmentID == nil {
                // Select first
                selectedSegmentID = segments.first?.id
            } else if let index = segments.firstIndex(where: { $0.id == selectedSegmentID }) {
                // Select next or deselect if at end
                if index < segments.count - 1 {
                    selectedSegmentID = segments[index + 1].id
                } else {
                    selectedSegmentID = nil // Reset to total
                }
            }
        }
    }
}
