//
//  QuoteTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 03/21/26.
//

import AppIntents
import WidgetKit

struct QuoteTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = QuoteEntry
	typealias Intent = QuoteConfigurationIntent

	func placeholder(in context: Context) -> QuoteEntry {
		QuoteEntry(
			date: .now,
			quote: "This is a placeholder quote.",
			isPlaceholder: true
		)
	}

	func snapshot(for configuration: QuoteConfigurationIntent, in context: Context) async -> QuoteEntry {
		if context.isPreview {
			return QuoteEntry(date: .now, quote: "Must be the water")
		}

		return QuoteEntry(date: .now, quote: configuration.quoteText)
	}

	func timeline(for configuration: QuoteConfigurationIntent, in context: Context) async -> Timeline<QuoteEntry> {
		let entry = QuoteEntry(date: .now, quote: configuration.quoteText)
		return Timeline(entries: [entry], policy: .never)
	}
}
