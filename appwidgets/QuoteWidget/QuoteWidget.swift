//
//  QuoteWidget.swift
//  appwidgets
//
//  Created by Nitish on 03/21/26.
//

import SwiftUI
import WidgetKit

struct QuoteWidget: Widget {
	let kind: String = "QuoteWidget"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: QuoteConfigurationIntent.self,
			provider: QuoteTimelineProvider()
		) { entry in
			QuoteWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.configurationDisplayName("smpl.quote")
		.description("A simple quote widget you can edit with your own text.")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

#Preview("Empty", as: .systemSmall) {
	QuoteWidget()
} timeline: {
	QuoteEntry(date: .now, quote: "")
}

#Preview("With Quote", as: .systemMedium) {
	QuoteWidget()
} timeline: {
	QuoteEntry(
		date: .now,
	quote: "")
	QuoteEntry(
		date: .now,
		quote: "")
}
