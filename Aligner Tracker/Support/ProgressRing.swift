//
//  ProgressRing.swift
//  Aligner Tracker
//
//  Reusable circular progress ring used by the home screen.
//

import SwiftUI

struct ProgressRing: View {
    /// 0...1 (values above 1 are clamped for the arc but allowed for the label).
    var progress: Double
    var lineWidth: CGFloat = 18
    var tint: Color = Theme.teal

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
    }
}
