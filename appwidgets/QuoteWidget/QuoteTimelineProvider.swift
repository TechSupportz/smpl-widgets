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

	private let premiumPreviewText = "Must be the water"

	func placeholder(in context: Context) -> QuoteEntry {
		QuoteEntry(
			date: .now,
			quote: premiumPreviewText,
			isPlaceholder: true,
			isLocked: !PremiumConfiguration.isUnlocked
		)
	}

	func snapshot(for configuration: QuoteConfigurationIntent, in context: Context) async -> QuoteEntry {
		if !PremiumConfiguration.isUnlocked {
			return QuoteEntry(date: .now, quote: premiumPreviewText, isLocked: true)
		}

		if context.isPreview {
			return QuoteEntry(date: .now, quote: premiumPreviewText)
		}

		return QuoteEntry(date: .now, quote: configuration.quoteText)
	}

	func timeline(for configuration: QuoteConfigurationIntent, in context: Context) async -> Timeline<QuoteEntry> {
		if !PremiumConfiguration.isUnlocked {
			let entry = QuoteEntry(date: .now, quote: premiumPreviewText, isLocked: true)
			return Timeline(entries: [entry], policy: .never)
		}

		let entry = QuoteEntry(date: .now, quote: configuration.quoteText)
		return Timeline(entries: [entry], policy: .never)
	}
}
