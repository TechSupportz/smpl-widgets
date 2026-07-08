//
//  CountdownEntry.swift
//  appwidgets
//
//  Created by Nitish on 06/07/26.
//

import Foundation
import WidgetKit

enum CountdownValidationError: Equatable {
	case futureStartDate
	case endBeforeStart
}

enum CountdownState: Equatable {
	case unconfigured
	case invalid(CountdownValidationError)
	case configured(title: String, remainingDays: Int, progress: Double)
}

struct CountdownEntry: TimelineEntry {
	let date: Date
	let state: CountdownState
	let accent: CountdownAccent

	static var preview: CountdownEntry {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

		let startDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .now
		let currentDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 3)) ?? .now
		let endDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 11)) ?? .now

		return CountdownEntry(
			date: currentDate,
			state: CountdownCalculator.state(
				title: "Mars trip",
				startDate: startDate,
				endDate: endDate,
				currentDate: currentDate,
				calendar: calendar
			),
			accent: .purple
		)
	}
}

enum CountdownCalculator {
	static func state(
		title: String,
		startDate: Date,
		endDate: Date?,
		currentDate: Date,
		calendar: Calendar = .current
	) -> CountdownState {
		guard let endDate else {
			return .unconfigured
		}

		let startDay = calendar.startOfDay(for: startDate)
		let endDay = calendar.startOfDay(for: endDate)
		let currentDay = calendar.startOfDay(for: currentDate)

		guard startDay <= currentDay else {
			return .invalid(.futureStartDate)
		}

		guard startDay <= endDay else {
			return .invalid(.endBeforeStart)
		}

		let totalDays = dayDistance(from: startDay, to: endDay, calendar: calendar)
		let elapsedDays = dayDistance(from: startDay, to: currentDay, calendar: calendar)
		let daysUntilEnd = dayDistance(from: currentDay, to: endDay, calendar: calendar)
		let remainingDays = max(0, daysUntilEnd)
		let progress =
			totalDays == 0
			? 1
			: min(1, max(0, Double(elapsedDays) / Double(totalDays)))

		return .configured(
			title: title,
			remainingDays: remainingDays,
			progress: progress
		)
	}

	private static func dayDistance(
		from startDate: Date,
		to endDate: Date,
		calendar: Calendar
	) -> Int {
		calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
	}
}
