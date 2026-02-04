//
//  EventWidget.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import SwiftUI
import WidgetKit

struct EventWidget: Widget {
	let kind: String = "EventWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(
			kind: kind,
			provider: EventTimelineProvider()
		) { entry in
			EventWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.configurationDisplayName("smpl.events")
		.description(
			"A simple widget which displays today's upcoming events and your upcoming events."
		)
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

#Preview("Small - With Events", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(
		date: .now, events: EventTimelineProvider.sampleUpcomingEvents, authState: .authorized)
}

#Preview("Small - Empty", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .authorized)
}

#Preview("Small - Permission Required", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .denied)
}

#Preview("Medium - With Events", as: .systemMedium) {
	EventWidget()
} timeline: {
	EventEntry(
		date: .now, events: EventTimelineProvider.sampleUpcomingEvents, authState: .authorized)
}

#Preview("Medium - Empty", as: .systemMedium) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .authorized)
}

#Preview("Medium - Permission Required", as: .systemMedium) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .denied)
}
