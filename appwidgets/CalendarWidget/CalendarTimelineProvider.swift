//
//  CalendarTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct CalendarTimelineProvider: TimelineProvider {
	func placeholder(in context: Context) -> CalendarEntry {
		CalendarEntry(date: Date())
	}

	func getSnapshot(in context: Context, completion: @escaping @Sendable (CalendarEntry) -> Void) {
		completion(CalendarEntry(date: Date()))
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<CalendarEntry>) -> Void
	) {
		let currentDate = Date()
		let startOfDay = Calendar.current.startOfDay(for: currentDate)
		let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

		let entry = CalendarEntry(date: currentDate)
		completion(Timeline(entries: [entry], policy: .after(endOfDay)))

	}

}
