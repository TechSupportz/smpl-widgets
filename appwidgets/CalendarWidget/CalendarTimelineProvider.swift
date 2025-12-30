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
		let startOfCurrentDay = Calendar.current.startOfDay(for: currentDate)
		let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfCurrentDay)!

		let entries = [CalendarEntry(date: startOfCurrentDay), CalendarEntry(date: startOfNextDay)]
		
		print(">>> startOfCurrentDay \(startOfCurrentDay)")
		print(">>> startOfNextDay \(startOfNextDay)")
		print(">>> entries \(entries)")
		
		completion(Timeline(entries: entries, policy: .atEnd))
	}

}
