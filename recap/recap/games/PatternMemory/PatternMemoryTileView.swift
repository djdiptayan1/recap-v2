//
//  PatternMemoryTileView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct PatternMemoryTileView: View {
    let tile: PatternTile
    let isLit: Bool
    let isInteractive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            if isInteractive { onTap() }
        }) {
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .fill(tile.color.opacity(isLit ? 1.0 : 0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                        .stroke(tile.color.opacity(0.6), lineWidth: isLit ? 0 : 1)
                )
                .shadow(
                    color: isLit ? tile.color.opacity(0.6) : Color.black.opacity(0.08),
                    radius: isLit ? 16 : 4,
                    x: 0, y: isLit ? 6 : 2
                )
                .scaleEffect(isLit ? 1.07 : 1.0)
                .animation(.easeInOut(duration: 0.18), value: isLit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInteractive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pattern tile")
        .accessibilityValue(isLit ? (isInteractive ? "Active" : "Shown") : "Hidden")
        .accessibilityHint(isInteractive ? "Tap to repeat this tile" : "Watch the sequence")
        .accessibilityInputLabels(["tile", "pattern tile", isLit ? "lit tile" : "dark tile"])
    }
}
