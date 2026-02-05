//
//  CalendarWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MonthCalendarWidgetView: View {
	var entry: MonthCalendarEntry
	private let calendar: Calendar = .current

	var body: some View {
		let monthDays = monthDays(for: entry.date)
		let weekdaySymbols = orderedWeekdaySymbols()

		VStack(spacing: 4) {
			Spacer()
			HStack(alignment: .lastTextBaseline) {
				Group {
					Text(entry.date, format: .dateTime.month(.wide))
					Spacer()
					Text(entry.date, format: .dateTime.year())
						.font(.system(size: 10))
						.fontWeight(.light)
				}
				.font(.system(size: 16))
				.fontWidth(.condensed)
				.fontWeight(.bold)
				.textCase(.uppercase)
			}
			.frame(maxWidth: .infinity)

			HStack(spacing: 6) {
				ForEach(weekdaySymbols, id: \.self) { symbol in
					Text(symbol)
						.font(.system(size: 10))
						.fontDesign(.monospaced)
						.foregroundStyle(.tertiary)
						.frame(maxWidth: .infinity)
				}
			}

			LazyVGrid(
				columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6
			) {
				ForEach(0..<42, id: \.self) { index in
					let day = monthDays[index]

					ZStack {
						if let day = day {
							if day.isToday {
								Circle()
									.fill(Color.red)
									.frame(width: 16, height: 16)
							}

							Text(day.formatted())
								.font(.system(size: 10))
								.fontWeight(day.isToday ? .semibold : .medium)
								.monospacedDigit()
								.foregroundStyle(day.isToday ? .white : .primary)
						} else {
							// placeholder to keep grid cells consistent
							Text("")
								.hidden()
						}
					}
					.frame(maxWidth: .infinity)
				}
			}
		}
		.widgetURL(URL(string: "smplwidgets://calendar"))
	}
}

private struct MonthDay {
	let value: Int
	let isToday: Bool

	func formatted() -> String {
		String(value)
	}
}

extension MonthCalendarWidgetView {
	fileprivate func orderedWeekdaySymbols() -> [String] {
		let symbols = calendar.veryShortStandaloneWeekdaySymbols
		let startIndex = calendar.firstWeekday - 1
		return Array(symbols[startIndex...] + symbols[..<startIndex])
	}

	fileprivate func monthDays(for date: Date) -> [MonthDay?] {
		// start of month
		let startOfMonth =
			calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date

		// number of days in month
		let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30

		// leading empty slots based on locale firstWeekday
		let startWeekday = calendar.component(.weekday, from: startOfMonth)
		let leadingEmpty = (startWeekday - calendar.firstWeekday + 7) % 7

		// compute today's components once (Option 1)
		let todayComponents = calendar.dateComponents([.year, .month, .day], from: date)
		let startComponents = calendar.dateComponents([.year, .month], from: startOfMonth)

		var days: [MonthDay?] = Array(repeating: nil, count: leadingEmpty)

		for day in 1...daysInMonth {
			let isToday =
				(todayComponents.year == startComponents.year
					&& todayComponents.month == startComponents.month && todayComponents.day == day)
			days.append(MonthDay(value: day, isToday: isToday))
		}

		if days.count < 42 {
			days.append(contentsOf: Array(repeating: nil, count: 42 - days.count))
		}

		return days
	}
}
