//
//  CalendarWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MinimalCalendarWidgetView: View {
	let entry: MinimalCalendarEntry

	private var currentDayNumber: Int {
		let weekday = Calendar.current.component(.weekday, from: entry.date)
		return ((weekday + 5) % 7) + 1
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
					Circle()
						.fill(dayNumber == 7 ? .red : .gray)
						.opacity(dayNumber <= currentDayNumber ? 1 : 0.2)
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
