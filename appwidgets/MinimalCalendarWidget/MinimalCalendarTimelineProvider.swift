//
//  MinimalCalendarTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MinimalCalendarTimelineProvider: TimelineProvider {
	func placeholder(in context: Context) -> MinimalCalendarEntry {
		MinimalCalendarEntry(date: Date())
	}

	func getSnapshot(in context: Context, completion: @escaping @Sendable (MinimalCalendarEntry) -> Void) {
		completion(MinimalCalendarEntry(date: Date()))
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<MinimalCalendarEntry>) -> Void
	) {
		let currentDate = Date()

		let entries = [
			MinimalCalendarEntry(date: currentDate.startOfDay),
			MinimalCalendarEntry(date: currentDate.startOfNextDay)
		]

		if SharedSettings.shared.isMockDataEnabled {
			var components = DateComponents()
			components.year = 2026
			components.month = 4
			components.day = 21
			let mockDate = Calendar.current.date(from: components) ?? currentDate
			completion(Timeline(entries: [MinimalCalendarEntry(date: mockDate)], policy: .never))
			return
		}

		completion(Timeline(entries: entries, policy: .atEnd))
	}
}
