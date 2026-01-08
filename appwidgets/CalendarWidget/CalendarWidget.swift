//
//  CalendarWidget.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct CalendarWidget: Widget {
	let kind: String = "CalendarWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(
			kind: kind,
			provider: CalendarTimelineProvider()
		) { entry in
			CalendarWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.configurationDisplayName("smpl.calendar")
		.description("A simple widget which displays the current day, month and date.")
		.supportedFamilies([.systemSmall])
	}
}

#Preview(as: .systemSmall) {
	CalendarWidget()
} timeline: {
	CalendarEntry(date: .now)
}
