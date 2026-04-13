//
//  EventTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import AppIntents
import EventKit
import SwiftUI
import WidgetKit

struct EventTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = EventEntry
	typealias Intent = EventConfigurationIntent

	func placeholder(in context: Context) -> EventEntry {
		Self.previewEntry(for: context.family)
	}

	func snapshot(
		for configuration: EventConfigurationIntent, in context: Context
	) async -> EventEntry {
		if context.isPreview {
			return Self.previewEntry(for: context.family)
		}

		let status = EKEventStore.authorizationStatus(for: .event)
		let authState = CalendarAuthState(from: status)

		if authState == .authorized {
			let upcomingEvents = fetchUpcomingEvents(for: configuration)
			return EventEntry(date: Date(), events: upcomingEvents, authState: authState)
		} else {
			return EventEntry(date: Date(), events: [], authState: authState)
		}
	}

	func timeline(
		for configuration: EventConfigurationIntent, in context: Context
	) async -> Timeline<EventEntry> {
		let currentDate = Date()

		let status = EKEventStore.authorizationStatus(for: .event)
		let authState = CalendarAuthState(from: status)

		switch authState {
		case .authorized:
			let upcomingEvents = fetchUpcomingEvents(for: configuration)

			// Calculate update dates based on event start/end times and 10-min post-end buffer
			var updateDates: Set<Date> = []

			// Always refresh at the start of the next day
			let calendar = Calendar.current
			let startOfNextDay = calendar.date(
				byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate))!
			updateDates.insert(startOfNextDay)

			// Add granular updates for event state changes from all week events
			for event in upcomingEvents {
				// 1. When event starts (upcoming -> in progress)
				if event.startDate > currentDate {
					updateDates.insert(event.startDate)
				}

				// 2. When event ends (in progress -> recently ended)
				if event.endDate > currentDate {
					updateDates.insert(event.endDate)
				}

				// 3. 10 minutes after event ends (recently ended -> removed)
				let tenMinutesAfterEnd = event.endDate.addingTimeInterval(600)
				if tenMinutesAfterEnd > currentDate && tenMinutesAfterEnd < startOfNextDay {
					updateDates.insert(tenMinutesAfterEnd)
				}
			}

			// Filter out past dates and sort
			let futureUpdates =
				updateDates
				.filter { $0 > currentDate }
				.sorted()

			// Create entries for now and each future update time
			var entries: [EventEntry] = []

			// Entry for right now
			entries.append(
				EventEntry(date: currentDate, events: upcomingEvents, authState: authState))

			// Entries for future updates
			for updateDate in futureUpdates {
				entries.append(
					EventEntry(date: updateDate, events: upcomingEvents, authState: authState))
			}

			// Use .atEnd policy so widget requests new timeline after the last entry
			return Timeline(entries: entries, policy: .atEnd)

		case .notDetermined:
			let entry = EventEntry(date: currentDate, events: [], authState: authState)
			// Check again in 15 minutes in case user grants permission
			let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
			return Timeline(entries: [entry], policy: .after(nextUpdate))

		case .denied, .restricted:
			let entry = EventEntry(date: currentDate, events: [], authState: authState)
			// Check again in 1 hour in case user changes settings
			let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
			return Timeline(entries: [entry], policy: .after(nextUpdate))
		}
	}

	private func fetchUpcomingEvents(for configuration: EventConfigurationIntent) -> [WidgetEvent] {
		let calendar = Calendar.current
		let now = Date()
		let startOfDay = calendar.startOfDay(for: now)
		let endOfWeek = calendar.date(byAdding: .day, value: 15, to: startOfDay)!
		let eventStore = EKEventStore()

		let predicate = eventStore.predicateForEvents(
			withStart: startOfDay,
			end: endOfWeek,
			calendars: selectedCalendars(for: configuration)
		)

		let ekEvents = eventStore.events(matching: predicate)
		return ekEvents.map { WidgetEvent(from: $0) }
	}

	private func selectedCalendars(for configuration: EventConfigurationIntent) -> [EKCalendar]? {
		let selectedCalendarIDs = Set(configuration.calendars?.map(\.id) ?? [])

		guard !selectedCalendarIDs.isEmpty else {
			return nil
		}

		let eventStore = EKEventStore()

		return eventStore.calendars(for: .event)
			.filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
	}

	// MARK: - Sample Data for Previews

	static func previewEntry(for family: WidgetFamily) -> EventEntry {
		EventEntry(date: previewReferenceDate, events: previewEvents(for: family), authState: .authorized)
	}

	static var previewReferenceDate: Date {
		var components = DateComponents()
		components.year = 2026
		components.month = 1
		components.day = 14
		components.hour = 9
		components.minute = 30

		return Calendar.current.date(from: components) ?? .now
	}

	static func previewEvents(for family: WidgetFamily) -> [WidgetEvent] {
		switch family {
		case .systemSmall:
			return smallPreviewEvents
		case .systemLarge:
			return largePreviewEvents
		default:
			return mediumPreviewEvents
		}
	}

	private static var smallPreviewEvents: [WidgetEvent] {
		[
			previewEvent(
				title: "Team Meeting",
				dayOffset: 0,
				startHour: 9,
				endHour: 10,
				calendarColor: .blue
			),
			previewEvent(
				title: "Coffee with Oscar",
				dayOffset: 0,
				startHour: 11,
				endHour: 12,
				location: "Pitstop Cafe",
				calendarColor: .orange
			),
		]
	}

	private static var mediumPreviewEvents: [WidgetEvent] {
		[
			previewEvent(
				title: "Project Deadline",
				dayOffset: 0,
				startHour: 0,
				startMinute: 0,
				endDayOffset: 1,
				endHour: 0,
				endMinute: 0,
				isAllDay: true,
				calendarColor: .teal
			),
			previewEvent(
				title: "Coffee with Oscar",
				dayOffset: 0,
				startHour: 11,
				endHour: 12,
				location: "Pitstop Cafe",
				calendarColor: .orange
			),
			previewEvent(
				title: "Review with Max",
				dayOffset: 1,
				startHour: 14,
				endHour: 15,
				calendarColor: .green
			),
			previewEvent(
				title: "Dentist",
				dayOffset: 2,
				startHour: 10,
				endHour: 11,
				calendarColor: .pink
			),
		]
	}

	private static var largePreviewEvents: [WidgetEvent] {
		[
			previewEvent(
				title: "Conference",
				dayOffset: 0,
				startHour: 0,
				startMinute: 0,
				endDayOffset: 1,
				endHour: 0,
				endMinute: 0,
				isAllDay: true,
				calendarColor: .teal
			),
			previewEvent(
				title: "Team Meeting",
				dayOffset: 0,
				startHour: 9,
				endHour: 10,
				calendarColor: .blue
			),
			previewEvent(
				title: "Coffee with Oscar",
				dayOffset: 0,
				startHour: 11,
				endHour: 12,
				location: "Pitstop Cafe",
				calendarColor: .orange
			),
			previewEvent(
				title: "Lunch",
				dayOffset: 0,
				startHour: 13,
				endHour: 14,
				calendarColor: .orange
			),
			previewEvent(
				title: "Run",
				dayOffset: 0,
				startHour: 18,
				endHour: 19,
				calendarColor: .purple
			),
			previewEvent(
				title: "Review with Max",
				dayOffset: 1,
				startHour: 14,
				endHour: 15,
				calendarColor: .green
			),
			previewEvent(
				title: "Dentist",
				dayOffset: 2,
				startHour: 10,
				endHour: 11,
				calendarColor: .pink
			),
			previewEvent(
				title: "Call with Charles",
				dayOffset: 2,
				startHour: 16,
				endHour: 17,
				calendarColor: .blue
			),
		]
	}

	private static func previewEvent(
		title: String,
		dayOffset: Int,
		startHour: Int,
		startMinute: Int = 0,
		endDayOffset: Int? = nil,
		endHour: Int,
		endMinute: Int = 0,
		isAllDay: Bool = false,
		location: String? = nil,
		calendarColor: Color
	) -> WidgetEvent {
		let startDate = previewDate(dayOffset: dayOffset, hour: startHour, minute: startMinute)
		let endDate = previewDate(
			dayOffset: endDayOffset ?? dayOffset,
			hour: endHour,
			minute: endMinute
		)

		return WidgetEvent(
			title: title,
			startDate: startDate,
			endDate: endDate,
			isAllDay: isAllDay,
			location: location,
			calendarColor: calendarColor
		)
	}

	private static func previewDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
		let calendar = Calendar.current
		let startOfDay = calendar.startOfDay(for: previewReferenceDate)
		let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) ?? startOfDay

		return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
	}
}