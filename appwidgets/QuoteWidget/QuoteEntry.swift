//
//  QuoteEntry.swift
//  appwidgets
//
//  Created by Nitish on 03/21/26.
//

import WidgetKit

struct QuoteEntry: TimelineEntry {
	let date: Date
	let quote: String
	let isPlaceholder: Bool

	init(date: Date, quote: String, isPlaceholder: Bool = false) {
		self.date = date
		self.quote = quote
		self.isPlaceholder = isPlaceholder
	}
}
