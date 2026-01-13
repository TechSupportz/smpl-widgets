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
		.description("A simple widget which displays today's upcoming events.")
		.supportedFamilies([.systemSmall])
	}
}

#Preview(as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: EventTimelineProvider.sampleEvents, authState: .authorized)
	EventEntry(date: .now, events: [], authState: .authorized)
	EventEntry(date: .now, events: [], authState: .denied)
}
