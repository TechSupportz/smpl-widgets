//
//  WeatherWidget.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct WeatherWidget: Widget {
	let kind: String = "WeatherWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(
			kind: kind,
			provider: WeatherTimelineProvider()
		) { entry in
			WeatherWidgetView(entry: entry)
				.containerBackground(.white, for: .widget)
				.environment(\.colorScheme, .light)
		}
		.configurationDisplayName("smpl.weather")
		.description("A simple widget which displays the current weather and temperature")
		.supportedFamilies([.systemSmall])
	}
}

#Preview("error-state", as: .systemSmall) {
	WeatherWidget()
} timeline: {
	WeatherEntry(
		date: .now,
		condition: "error",
		temperature: Measurement<UnitTemperature>(value: 25, unit: .celsius),
		symbol: "questionmark.square.dashed"
	)
}

#Preview("location-error-state", as: .systemSmall) {
	WeatherWidget()
} timeline: {
	WeatherEntry(
		date: .now,
		condition: "error,location",
		temperature: Measurement<UnitTemperature>(value: 25, unit: .celsius),
		symbol: "questionmark.square.dashed"
	)
}

#Preview("placeholder-state", as: .systemSmall) {
	WeatherWidget()
} timeline: {
	WeatherEntry(
		date: .now,
		condition: "cloudy",
		temperature: Measurement<UnitTemperature>(value: 25, unit: .celsius),
		symbol: "cloud.fill"
	)
}
