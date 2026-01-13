//
//  CalendarWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MinimalCalendarWidgetView: View {
	var entry: MinimalCalendarEntry

	var currentDayNumber: Int {
		switch entry.date.formatted(.dateTime.weekday()) {
		case "Mon": 1
		case "Tue": 2
		case "Wed": 3
		case "Thu": 4
		case "Fri": 5
		case "Sat": 6
		case "Sun": 7
		default: 7
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			Text(entry.date, format: .dateTime.month(.twoDigits))
				.font(.system(size: 22))
				.fontDesign(.monospaced)
				.padding(.vertical, -4)
				.foregroundStyle(Color.gray)
				.frame(
					maxWidth: .infinity,
					minHeight: 22,
					maxHeight: 22,
					alignment: .topTrailing
				)
			Spacer()
			Text(entry.date, format: .dateTime.day())
				.font(.system(size: 104))
				.fontWidth(.compressed)
				.fontWeight(.bold)
				.kerning(-4)
				.padding(.vertical, -34)
				.padding(.leading, -2)
				.contentTransition(.numericText())
			Spacer()
			LazyVGrid(
				columns: Array(repeating: GridItem(.fixed(6.5), spacing: 2), count: 3),
				alignment: .leading,
				spacing: 2
			) {
				ForEach(1...7, id: \.self) { dayNumber in
					if dayNumber <= currentDayNumber {
						Circle().fill(dayNumber == 7 ? .red : .gray)
					}
					if dayNumber > currentDayNumber { Circle().fill(dayNumber == 7 ? .red : .gray).opacity(0.2) }
				}
			}
			.frame(
				maxWidth: .infinity,
				minHeight: 22,
				maxHeight: 22,
				alignment: .bottom
			)
		}
		.frame(
			maxWidth: .infinity,
		)
		.widgetURL(URL(string: "smplwidgets://calendar"))
	}
}
