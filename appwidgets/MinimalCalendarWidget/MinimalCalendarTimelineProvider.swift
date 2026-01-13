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

		completion(Timeline(entries: entries, policy: .atEnd))
	}
}
