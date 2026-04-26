//
//  WeatherEntry.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import WidgetKit

struct WeatherEntry: TimelineEntry {
	let date: Date
	let condition: String
	let temperature: Measurement<UnitTemperature>
	let symbol: String
	let isLocked: Bool

	init(
		date: Date,
		condition: String,
		temperature: Measurement<UnitTemperature>,
		symbol: String,
		isLocked: Bool = false
	) {
		self.date = date
		self.condition = condition
		self.temperature = temperature
		self.symbol = symbol
		self.isLocked = isLocked
	}
}
