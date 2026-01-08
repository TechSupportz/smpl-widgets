//
//  CalendarWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct CalendarWidgetView: View {
	var entry: CalendarEntry

	var body: some View {
		VStack(spacing: 8) {
			HStack(spacing: 4) {
				Text(entry.date, format: .dateTime.weekday())
					.fontWeight(.bold)
					.foregroundStyle(.red)
				Text(entry.date, format: .dateTime.month())
					.fontWeight(.light)
			}
			.font(.system(size: 26))
			.fontWidth(.condensed)
			.padding(.vertical, -4)
			Text(entry.date, format: .dateTime.day())
				.font(.system(size: 128))
				.fontWidth(.compressed)
				.fontWeight(.bold)
				.monospacedDigit()
				.padding(.vertical, -30)
				.multilineTextAlignment(.center)
				.contentTransition(.numericText())
		}
		.frame(
			minWidth: 0,
			maxWidth: .infinity,
		)
		.widgetURL(URL(string: "smplwidgets://calendar"))
	}
}
