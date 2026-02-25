//
//  QuarterlyAverageChart.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct QuarterlyAverageChart: View {
    let data: [AnalyticsData]
    @Binding var selectedPoint: AnalyticsData?
    
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Month", item.label),
                y: .value("Average", item.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(8)
            .annotation(position: .top) {
                Text("\(Int(item.value))%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .chartYScale(domain: 0...100)
    }
}
