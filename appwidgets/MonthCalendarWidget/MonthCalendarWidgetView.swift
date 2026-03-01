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
	@Environment(\.widgetRenderingMode) var renderingMode

	private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

	var body: some View {
		let monthDays = monthDays(for: entry.date)
		let weekdayInfo = orderedWeekdayInfo()

		Spacer()
		VStack(alignment: .leading, spacing: 2) {
			HStack(alignment: .lastTextBaseline) {
				Text(entry.date, format: .dateTime.month(.wide))
					.font(.system(size: 16))
					.fontWidth(.condensed)
					.fontWeight(.bold)
					.textCase(.uppercase)
				Spacer()
				Text(entry.date, format: .dateTime.year())
					.font(.system(size: 10))
					.fontWidth(.condensed)
					.fontWeight(.light)
			}

			LazyVGrid(columns: columns, spacing: 0) {
				ForEach(weekdayInfo) { day in
					Text(day.symbol)
						.font(.system(size: 9))
						.fontDesign(.monospaced)
						.foregroundStyle(.tertiary)
						.frame(maxWidth: .infinity, minHeight: 14, maxHeight: 14)
				}
			}

			LazyVGrid(columns: columns, spacing: 0) {
				ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
					if let day = day {
						ZStack {
							Circle()
								.fill(
									renderingMode == .accented
										? Color.white.opacity(0.25)
										: renderingMode == .vibrant
											? Color.white.opacity(0.5)
											: Color.red
								)
								.widgetAccentable()
								.opacity(day.isToday ? 1 : 0)

							Text(day.formatted())
								.kerning(-0.5)
								.font(.system(size: 10))
								.fontWeight(day.isToday ? .semibold : .medium)
								.monospacedDigit()
								.foregroundStyle(day.isToday ? .white : .primary)
						}
						.frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16)
					} else {
						Color.clear
							.frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16)
					}
				}
			}
		}
		Spacer()
			.widgetURL(URL(string: "smplwidgets://calendar"))
	}
}

private struct MonthDay: Hashable {
	let value: Int
	let isToday: Bool

	func formatted() -> String {
		String(value)
	}
}

extension MonthCalendarWidgetView {
	fileprivate struct WeekdayInfo: Identifiable {
		let id: Int
		let symbol: String
	}

	fileprivate func orderedWeekdayInfo() -> [WeekdayInfo] {
		let symbols = calendar.veryShortStandaloneWeekdaySymbols
		let startIndex = calendar.firstWeekday - 1
		let ordered = Array(symbols[startIndex...] + symbols[..<startIndex])

		return ordered.enumerated()
			.map { index, symbol in
				let weekdayNumber = ((startIndex + index) % 7) + 1
				return WeekdayInfo(id: weekdayNumber, symbol: symbol)
			}
	}

	fileprivate func monthDays(for date: Date) -> [MonthDay?] {
		let startOfMonth =
			calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date

		let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30

		let startWeekday = calendar.component(.weekday, from: startOfMonth)
		let leadingEmpty = (startWeekday - calendar.firstWeekday + 7) % 7

		let todayComponents = calendar.dateComponents([.year, .month, .day], from: date)
		let startComponents = calendar.dateComponents([.year, .month], from: startOfMonth)

		var days: [MonthDay?] = Array(repeating: nil, count: leadingEmpty)

		for day in 1...daysInMonth {
			let isToday =
				(todayComponents.year == startComponents.year
					&& todayComponents.month == startComponents.month
					&& todayComponents.day == day)
			days.append(MonthDay(value: day, isToday: isToday))
		}

		if days.count < 42 {
			days.append(contentsOf: Array(repeating: nil, count: 42 - days.count))
		}

		return days
	}
}
