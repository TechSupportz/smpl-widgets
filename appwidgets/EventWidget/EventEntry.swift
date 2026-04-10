//
//  EventEntry.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import SwiftUI
import WidgetKit
import EventKit

#if canImport(UIKit)
	import UIKit
#endif

/// Authorization state for the widget to display appropriate UI
enum CalendarAuthState {
	case authorized
	case notDetermined
	case denied
	case restricted

	init(from status: EKAuthorizationStatus) {
		switch status {
		case .fullAccess, .authorized:
			self = .authorized
		case .notDetermined:
			self = .notDetermined
		case .denied:
			self = .denied
		case .restricted, .writeOnly:
			self = .restricted
		@unknown default:
			self = .denied
		}
	}
}

/// Represents a single calendar event for display in the widget
struct WidgetEvent: Identifiable {
	let id: String
	let title: String
	let startDate: Date
	let endDate: Date
	let isAllDay: Bool
	let location: String?
	let calendarColor: Color

	init(from ekEvent: EKEvent) {
		self.id = ekEvent.eventIdentifier ?? UUID().uuidString
		self.title = ekEvent.title ?? "Untitled Event"
		self.startDate = ekEvent.startDate
		self.endDate = ekEvent.endDate
		self.isAllDay = ekEvent.isAllDay
		self.location = ekEvent.location
		self.calendarColor = Self.calendarColor(for: ekEvent.calendar)
	}

	/// Initializer for previews and placeholders
	init(
		id: String = UUID().uuidString,
		title: String,
		startDate: Date,
		endDate: Date,
		isAllDay: Bool = false,
		location: String? = nil,
		calendarColor: Color = .red
	) {
		self.id = id
		self.title = title
		self.startDate = startDate
		self.endDate = endDate
		self.isAllDay = isAllDay
		self.location = location
		self.calendarColor = calendarColor
	}

	// MARK: - Event State Logic

	enum EventState {
		case upcoming // hasn't started
		case inProgress // started but not ended
		case recentlyEnded // ended within last 10 minutes
	}

	func state(at date: Date) -> EventState {
		if date < startDate {
			return .upcoming
		} else if date >= startDate && date < endDate {
			return .inProgress
		} else {
			return .recentlyEnded
		}
	}

	func pillColor(at date: Date) -> Color {
		switch state(at: date) {
		case .upcoming:
			return calendarColor.opacity(0.5)
		case .inProgress, .recentlyEnded:
			return calendarColor
		}
	}

	func overlaps(day: Date, calendar: Calendar = .current) -> Bool {
		let dayStart = calendar.startOfDay(for: day)
		let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

		return startDate < dayEnd && endDate > dayStart
	}

	func overlaps(start: Date, end: Date) -> Bool {
		startDate < end && endDate > start
	}

	func spansMultipleDays(calendar: Calendar = .current) -> Bool {
		let startDay = calendar.startOfDay(for: startDate)
		let effectiveEndDate = endDate.addingTimeInterval(-1)
		let endDay = calendar.startOfDay(for: effectiveEndDate)

		return startDay < endDay
	}

	func upcomingDisplayDay(relativeTo date: Date, calendar: Calendar = .current) -> Date {
		let today = calendar.startOfDay(for: date)
		let startDay = calendar.startOfDay(for: startDate)

		return max(today, startDay)
	}

	private static func calendarColor(for calendar: EKCalendar) -> Color {
		#if canImport(UIKit)
			if let cgColor = calendar.cgColor {
				return Color(uiColor: UIColor(cgColor: cgColor))
			}
		#endif

		return .blue
	}
}

struct EventEntry: TimelineEntry {
	let date: Date
	let events: [WidgetEvent]
	let authState: CalendarAuthState

	/// Convenience initializer with default authorized state (for previews)
	init(date: Date, events: [WidgetEvent], authState: CalendarAuthState = .authorized) {
		self.date = date
		self.events = events
		self.authState = authState
	}

	var todayEventCount: Int {
		let calendar = Calendar.current

		return events.count(where: { $0.overlaps(day: date, calendar: calendar) })
	}

	var eventCount: Int {
		events.count
	}
	
	var todayHasEvents: Bool {
		todayEventCount > 0
	}

	var hasEvents: Bool {
		!events.isEmpty
	}

	var isAuthorized: Bool {
		authState == .authorized
	}

	/// Sorted events: all-day events first, then by start time
	var sortedEvents: [WidgetEvent] {
		events.sorted { first, second in
			if first.isAllDay && !second.isAllDay {
				return true
			} else if !first.isAllDay && second.isAllDay {
				return false
			} else {
				return first.startDate < second.startDate
			}
		}
	}

	/// Filtered events for display (today only):
	/// 1. Haven't ended yet
	/// 2. OR ended less than 10 minutes ago
	var displayableEvents: [WidgetEvent] {
		let tenMinutesAgo = date.addingTimeInterval(-600)
		let todayEvents = todayEvents

		return
			todayEvents.sorted { first, second in
				if first.isAllDay && !second.isAllDay {
					return true
				} else if !first.isAllDay && second.isAllDay {
					return false
				} else {
					return first.startDate < second.startDate
				}
			}
			.filter { event in
				if event.isAllDay {
					return event.endDate > date
				} else {
					return event.endDate > tenMinutesAgo
				}
			}
	}

	/// Check if there are any displayable events
	var hasDisplayableEvents: Bool {
		!displayableEvents.isEmpty
	}

	// MARK: - Upcoming Events Logic

	/// Events within today + 14 days (flat upcoming events list)
	var upcomingEvents: [WidgetEvent] {
		let calendar = Calendar.current
		let startOfToday = calendar.startOfDay(for: date)
		let startOfAfterWeek = calendar.date(byAdding: .day, value: 14, to: startOfToday)!

		return events.filter { event in
			event.overlaps(start: startOfToday, end: startOfAfterWeek)
		}
	}

	/// Returns today's events from the upcoming list
	var todayEvents: [WidgetEvent] {
		let calendar = Calendar.current
		return upcomingEvents.filter { $0.overlaps(day: date, calendar: calendar) }
	}

	/// Returns events for upcoming days (excluding today), sorted by date
	var upcomingDaysEvents: [(date: Date, events: [WidgetEvent])] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: date)
		let endOfRange = calendar.date(byAdding: .day, value: 14, to: today)!

		return Dictionary(grouping: upcomingEvents) {
			$0.upcomingDisplayDay(relativeTo: date, calendar: calendar)
		}
		.filter { $0.key > today && $0.key < endOfRange }
		.sorted { $0.key < $1.key }
		.map { groupedDay in
			(
				date: groupedDay.key,
				events: groupedDay.value.sorted { $0.startDate < $1.startDate }
			)
		}
	}

	/// Check if there are any events in the next 14 days
	var hasUpcomingEvents: Bool {
		!upcomingEvents.isEmpty
	}

	/// All displayable events from today (sorted and filtered)
	var todayDisplayableEvents: [WidgetEvent] {
		displayableEvents
	}
}
