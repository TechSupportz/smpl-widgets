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
		VStack(spacing: 12) {
			HStack(spacing: 4) {
				Text(entry.date, format: .dateTime.weekday())
					.fontWeight(.bold)
					.foregroundStyle(.red)
				Text(entry.date, format: .dateTime.month())
					.fontWeight(.light)
			}
			.font(.system(size: 24))
			.fontWidth(.condensed)
			.padding(.vertical, -4)
			Text(entry.date, format: .dateTime.day())
				.font(.system(size: 128))
				.fontWidth(.compressed)
				.fontWeight(.bold)
				.kerning(-4)
				.padding(.vertical, -30)
				.contentTransition(.numericText())
		}
		.frame(
			minWidth: 0,
			maxWidth: .infinity,
			alignment: .center
		)
		.widgetURL(URL(string: "smplwidgets://calendar"))
	}
}
