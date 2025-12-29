//
//  WeatherTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct WeatherTimelineProvider: TimelineProvider {
	func placeholder(in context: Context) -> WeatherEntry {
		WeatherEntry(date: Date())
	}

	func getSnapshot(in context: Context, completion: @escaping @Sendable (WeatherEntry) -> Void) {
		completion(WeatherEntry(date: Date()))
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<WeatherEntry>) -> Void
	) {
		let currentDate = Date()
		let startOfDay = Calendar.current.startOfDay(for: currentDate)
		let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

		let entry = WeatherEntry(date: currentDate)
		completion(Timeline(entries: [entry], policy: .after(endOfDay)))

	}

}
