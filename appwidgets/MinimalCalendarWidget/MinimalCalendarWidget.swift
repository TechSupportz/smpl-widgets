//
//  MinimalCalendarWidget.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MinimalCalendarWidget: Widget {
	let kind: String = "MinimalCalendarWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(
			kind: kind,
			provider: MinimalCalendarTimelineProvider()
		) { entry in
			MinimalCalendarWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.configurationDisplayName("smpl.calendar.ii")
		.description("A simple widget which displays the current day, month and date.")
		.supportedFamilies([.systemSmall])
	}
}

#Preview(as: .systemSmall) {
	MinimalCalendarWidget()
} timeline: {
	MinimalCalendarEntry(date: .now)
}
