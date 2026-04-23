//
//  WeeklyTrendChart.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct WeeklyTrendChart: View {
    let data: [AnalyticsData]
    @Binding var selectedPoint: AnalyticsData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart(data) { item in
                // Gradient Area
                AreaMark(
                    x: .value("Day", item.label),
                    y: .value("Score", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppConfig.Colors.accent.opacity(0.4), AppConfig.Colors.accent.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // The Line
                LineMark(
                    x: .value("Day", item.label),
                    y: .value("Score", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppConfig.Colors.accent)
                .symbol {
                    Circle()
                        .fill(AppConfig.Colors.accent)
                        .frame(width: 8, height: 8)
                        .shadow(radius: 2)
                }
                
                if let selected = selectedPoint, selected.id == item.id {
                    PointMark(x: .value("Day", item.label), y: .value("Score", item.value))
                        .foregroundStyle(AppConfig.Colors.textPrimary)
                        .symbolSize(100)
                }
            }
            .chartYScale(domain: 0...100)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture().onChanged { value in
                            let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                            if let label: String = proxy.value(atX: x) {
                                if let match = data.first(where: { $0.label == label }) {
                                    self.selectedPoint = match
                                }
                            }
                        }.onEnded { _ in self.selectedPoint = nil })
                }
            }
            .accessibilityLabel("Weekly trend chart")
            .accessibilityValue(selectedPoint == nil ? "Showing weekly trend" : "Selected point \(selectedPoint!.label), \(Int(selectedPoint!.value)) percent")

            VStack(alignment: .leading, spacing: 6) {
                ForEach(data) { item in
                    Text("\(item.label): \(Int(item.value)) percent")
                        .font(.caption)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            .accessibilityHidden(true)
        }
    }
}
