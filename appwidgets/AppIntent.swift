//
//  AppIntent.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import AppIntents
import Foundation
import WidgetKit

struct QuoteConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Quote" }
	static var description: IntentDescription { "Choose the text shown in your quote widget." }

	@Parameter(
		title: "Enter your quote...",
		inputOptions: String.IntentInputOptions(multiline: true)
	)
	var quote: String?
}

extension QuoteConfigurationIntent {
	var quoteText: String {
		quote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	}
}
