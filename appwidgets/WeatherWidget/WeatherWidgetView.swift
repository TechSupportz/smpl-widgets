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
	
	var isError: Bool {
		entry.condition == "error"
	}

	var body: some View {
			VStack() {
				VStack(alignment: .leading, spacing: 8) {
					Text("\(isError ? "Loading..." : entry.condition.capitalized)")
						.font(.system(size: 24))
						.padding(.vertical, -5)
						.fontWidth(.condensed)
						.fontWeight(.semibold)
					Text("\(isError ? "?" : entry.temperature.value.rounded().formatted())°")
						.font(.system(size: 32))
						.padding(.vertical, -5)
						.fontWidth(.compressed)
						.fontWeight(.medium)
						.foregroundColor(.secondary)

				}
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					alignment: .topLeading
				)
				Spacer()
				Image(systemName: entry.symbol)
					.font(.system(size: 64))
					.fontWidth(.compressed)
					.fontWeight(.medium)
					.frame(
						minWidth: 0,
						maxWidth: .infinity,
						alignment: .bottomTrailing
					)
				// NOTE: ONLY FOR DEBUGGING
				Text(entry.date.formatted(date: .numeric, time: .shortened))
					.font(.system(size: 8, design: .monospaced))
					.foregroundColor(.secondary)
					.offset(x: 0, y: 4)
			}
			.widgetURL(URL(string: "weather://"))
		}
	}
