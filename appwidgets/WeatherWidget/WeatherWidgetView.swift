//
//  WeatherWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
	var entry: WeatherEntry

	var conditionText: String {
		entry.condition.contains("error")
			? entry.condition.contains("location") ? "Location" : "error" : entry.condition
	}

	var temperatureText: String {
		entry.condition.contains("error")
			? entry.condition.contains("location") ? "Error" : "?°"
			: "\(entry.temperature.value.rounded().formatted())°"
	}

	var symbol: String {
		entry.condition == "error,location" ? "location.slash.circle" : entry.symbol
	}

	var body: some View {
		VStack {
			VStack(alignment: .leading, spacing: 8) {
				Text(conditionText.capitalized)
					.font(.system(size: 26))
					.padding(.vertical, -5)
					.fontWidth(.condensed)
					.fontWeight(.semibold)
					.minimumScaleFactor(0.5)
					.lineLimit(2)
				Text(temperatureText)
					.font(.system(size: 32))
					.padding(.vertical, -6)
					.fontWidth(.compressed)
					.fontWeight(.medium)
					.foregroundColor(.secondary)
					.contentTransition(.numericText())
			}
			.frame(
				minWidth: 0,
				maxWidth: .infinity,
				alignment: .topLeading
			)
			Spacer()
			Image(systemName: symbol)
				.font(.system(size: 64))
				.fontWidth(.compressed)
				.fontWeight(.medium)
				.scaledToFit()
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					minHeight: 64,
					maxHeight: 64,
					alignment: .bottomTrailing
				)
		}
		.widgetURL(URL(string: "smplwidgets://weather"))
	}
}
