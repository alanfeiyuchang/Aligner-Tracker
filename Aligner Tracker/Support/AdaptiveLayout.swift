//
//  AdaptiveLayout.swift
//  Aligner Tracker
//
//  Layout helpers for canvases wider than a phone: the iPhone Duo's unfolded
//  inner screen (669 × 951 pt, either way up). Every decision is made from the
//  width the view is actually given, never from the device, and every
//  threshold sits above the widest canvas an ordinary iPhone or the Duo's
//  outer screen can offer (466 pt) — so on those the views lay out exactly as
//  they did before these helpers existed. See docs/iphone-duo.md.
//

import SwiftUI

enum WideLayout {
    /// Single-column content stops growing here and is centred instead.
    static let readableWidth: CGFloat = 600
    /// From here up, Home and History split into two columns.
    static let twoColumnWidth: CGFloat = 700
    /// Two-column content stops growing here.
    static let twoColumnMaxWidth: CGFloat = 900

    static func isTwoColumn(_ width: CGFloat) -> Bool { width >= twoColumnWidth }

    /// A vertical stack on a phone-width canvas, side-by-side columns on a wide
    /// one. One layout type either way, so folding the phone re-flows the same
    /// views instead of rebuilding them.
    static func columns(width: CGFloat, spacing: CGFloat) -> AnyLayout {
        isTwoColumn(width)
            ? AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
            : AnyLayout(VStackLayout(spacing: spacing))
    }

    /// Extra horizontal margin that centres content capped at `maxWidth`.
    /// `nil` — "leave the system default alone" — whenever the canvas is not
    /// wider than the cap, which is always the case on a phone.
    static func margin(width: CGFloat, maxWidth: CGFloat) -> CGFloat? {
        width > maxWidth ? (width - maxWidth) / 2 : nil
    }
}

private struct ContentWidthCap: ViewModifier {
    @Binding var width: CGFloat
    var maxWidth: (CGFloat) -> CGFloat

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .contentMargins(.horizontal,
                            WideLayout.margin(width: width, maxWidth: maxWidth(width)),
                            for: .scrollContent)
    }
}

private struct ReadableWidth: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content.modifier(ContentWidthCap(width: $width) { _ in WideLayout.readableWidth })
    }
}

extension View {
    /// For a `ScrollView`, `List` or `Form`: keeps the scrolling content at a
    /// readable width and centres it once the canvas is wider than that. The
    /// scroll view itself still spans the canvas, so its background and the
    /// scroll gesture reach edge to edge.
    func readableContentWidth() -> some View {
        modifier(ReadableWidth())
    }

    /// Like `readableContentWidth()`, for screens that switch to two columns
    /// (see `WideLayout.columns`): reports the canvas width into `width` and
    /// caps the content for whichever arrangement that width selects.
    func adaptiveContentWidth(_ width: Binding<CGFloat>) -> some View {
        modifier(ContentWidthCap(width: width) {
            WideLayout.isTwoColumn($0) ? WideLayout.twoColumnMaxWidth : WideLayout.readableWidth
        })
    }
}
