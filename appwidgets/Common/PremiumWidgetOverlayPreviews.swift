//
//  PremiumWidgetOverlayPreviews.swift
//  appwidgets
//
//  Created by OpenCode on 26/04/26.
//

#if DEBUG
import SwiftUI
import WidgetKit

private struct PremiumOverlayPreviewEntry: TimelineEntry {
	let date: Date
	let isLocked: Bool
	let priceText: String?
}

private struct PremiumOverlayPreviewProvider: TimelineProvider {
	func placeholder(in context: Context) -> PremiumOverlayPreviewEntry {
		PremiumOverlayPreviewEntry(date: .now, isLocked: true, priceText: "$4.99")
	}

	func getSnapshot(
		in context: Context,
		completion: @escaping @Sendable (PremiumOverlayPreviewEntry) -> Void
	) {
		completion(PremiumOverlayPreviewEntry(date: .now, isLocked: true, priceText: "$4.99"))
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<PremiumOverlayPreviewEntry>) -> Void
	) {
		completion(Timeline(entries: [placeholder(in: context)], policy: .never))
	}
}

private struct PremiumOverlayPreviewWidgetView: View {
	let entry: PremiumOverlayPreviewEntry

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(Color(red: 0.18, green: 0.43, blue: 0.98))

			Text("42")
				.font(.system(size: 100, weight: .bold, design: .rounded))
				.foregroundStyle(.white)
		}
		.premiumLockedWidgetStyle(isLocked: entry.isLocked, priceText: entry.priceText)
		.containerBackground(.white, for: .widget)
	}
}

private struct PremiumOverlayPreviewWidget: Widget {
	let kind: String = "PremiumOverlayPreviewWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(
			kind: kind,
			provider: PremiumOverlayPreviewProvider()
		) { entry in
			PremiumOverlayPreviewWidgetView(entry: entry)
		}
		.configurationDisplayName("Premium Overlay Preview")
		.description("Debug-only preview for the premium overlay.")
		.supportedFamilies([.systemSmall])
	}
}

#Preview("Locked - with price", as: .systemSmall) {
	PremiumOverlayPreviewWidget()
} timeline: {
	PremiumOverlayPreviewEntry(date: .now, isLocked: true, priceText: "$4.99")
}

#Preview("Locked - no price", as: .systemSmall) {
	PremiumOverlayPreviewWidget()
} timeline: {
	PremiumOverlayPreviewEntry(date: .now, isLocked: true, priceText: nil)
}

#Preview("Unlocked", as: .systemSmall) {
	PremiumOverlayPreviewWidget()
} timeline: {
	PremiumOverlayPreviewEntry(date: .now, isLocked: false, priceText: "$4.99")
}
#endif
