//
//  CountdownWidget.swift
//  appwidgets
//
//  Created by Nitish on 06/07/26.
//

import SwiftUI
import WidgetKit

struct CountdownWidget: Widget {
	let kind: String = "CountdownWidget"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: CountdownConfigurationIntent.self,
			provider: CountdownTimelineProvider()
		) { entry in
			CountdownWidgetView(entry: entry)
				.containerBackground(.background, for: .widget)
		}
		.configurationDisplayName("smpl.countdown")
			.description("Count down to something worth waiting for. Dates use DDMMYYYY.")
		.supportedFamilies([.systemSmall])
	}
}

#Preview("Configured", as: .systemSmall) {
	CountdownWidget()
} timeline: {
	CountdownEntry.preview
}

#Preview("Unconfigured", as: .systemSmall) {
	CountdownWidget()
} timeline: {
	CountdownEntry(date: .now, state: .unconfigured, accent: .teal)
}

#Preview("Invalid", as: .systemSmall) {
	CountdownWidget()
} timeline: {
	CountdownEntry(date: .now, state: .invalid(.futureStartDate), accent: .teal)
}
