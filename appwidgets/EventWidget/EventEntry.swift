//
//  EventEntry.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import EventKit
import SwiftUI
import WidgetKit


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

	init(from ekEvent: EKEvent) {
		self.id = ekEvent.eventIdentifier ?? UUID().uuidString
		self.title = ekEvent.title ?? "Untitled Event"
		self.startDate = ekEvent.startDate
		self.endDate = ekEvent.endDate
		self.isAllDay = ekEvent.isAllDay
		self.location = ekEvent.location
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
	}

	// MARK: - Event State Logic

	enum EventState {
		case upcoming  // hasn't started
		case inProgress  // started but not ended
		case recentlyEnded  // ended within last 10 minutes
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
		if isAllDay {
			// All-day events are always blue unless day is over (handled by filtering)
			return .blue
		}

		switch state(at: date) {
		case .upcoming:
			return Color.gray.opacity(0.3)
		case .inProgress:
			return .orange
		case .recentlyEnded:
			return .green
		}
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

	var eventCount: Int {
		events.count
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

	/// Filtered events for display:
	/// 1. Haven't ended yet
	/// 2. OR ended less than 10 minutes ago
	var displayableEvents: [WidgetEvent] {
		let tenMinutesAgo = date.addingTimeInterval(-600)  // 10 minutes = 600 seconds

		return sortedEvents.filter { event in
			if event.isAllDay {
				// Show all-day events for the current day
				// Assuming 'events' only contains today's events, so just check start/end relative to day
				// But simpler: just check if it ends after "now" (which is effectively midnight for all-day)
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
}
