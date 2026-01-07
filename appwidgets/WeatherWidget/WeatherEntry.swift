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
}
