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
		AppIntentConfiguration(
			kind: kind,
			intent: EventConfigurationIntent.self,
			provider: EventTimelineProvider()
		) { entry in
			EventWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.configurationDisplayName("smpl.events")
		.description(
			"A simple widget which displays today's upcoming events and your upcoming events."
		)
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

#Preview("Small", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventTimelineProvider.previewEntry(for: .systemSmall)
	EventEntry(date: .now, events: [], authState: .authorized)
	EventEntry(date: .now, events: [], authState: .denied)
}

#Preview("Medium", as: .systemMedium) {
	EventWidget()
} timeline: {
	EventTimelineProvider.previewEntry(for: .systemMedium)
	EventEntry(date: .now, events: [], authState: .authorized)
	EventEntry(date: .now, events: [], authState: .denied)
}

#Preview("Large", as: .systemLarge) {
	EventWidget()
} timeline: {
	EventTimelineProvider.previewEntry(for: .systemLarge)
	EventEntry(date: .now, events: [], authState: .authorized)
	EventEntry(date: .now, events: [], authState: .denied)
}
