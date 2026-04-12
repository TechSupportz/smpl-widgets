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
		EventEntry(date: Date(), events: Self.sampleEvents, authState: .authorized)
	}

	func snapshot(
		for configuration: EventConfigurationIntent, in context: Context
	) async -> EventEntry {
		if context.isPreview {
			return EventEntry(
				date: Date(), events: Self.sampleUpcomingEvents, authState: .authorized)
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

	static var sampleEvents: [WidgetEvent] {
		let now = Date()
		let calendar = Calendar.current
		let startOfToday = calendar.startOfDay(for: now)
		let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

		return [
			WidgetEvent(
				title: "Team Standup",
				startDate: startOfToday,
				endDate: startOfTomorrow,
				isAllDay: true,
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Focus Time",
				startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				calendarColor: .mint
			),
			WidgetEvent(
				title: "Dinner with Oscar",
				startDate: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				calendarColor: .green
			),
			WidgetEvent(
				title: "Project Review",
				startDate: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				calendarColor: .orange
			),
			WidgetEvent(
				title: "Client Meeting",
				startDate: calendar.date(bySettingHour: 21, minute: 30, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 22, minute: 30, second: 0, of: now)!,
				isAllDay: false,
				location: "Conference Room A",
				calendarColor: .purple
			),
			WidgetEvent(
				title: "Design Sync",
				startDate: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 23, minute: 30, second: 0, of: now)!,
				isAllDay: false,
				location: "Zoom",
				calendarColor: .red
			),
		]
	}

	static var sampleUpcomingEvents: [WidgetEvent] {
		let now = Date()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: now)
		let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
		let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
		let day3 = calendar.date(byAdding: .day, value: 3, to: today)!
		let day5 = calendar.date(byAdding: .day, value: 5, to: today)!

		return sampleEvents + [
			WidgetEvent(
				title: "Morning Jog",
				startDate: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow)!,
				endDate: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)!,
				isAllDay: false,
				calendarColor: .green
			),
			WidgetEvent(
				title: "Sprint Planning",
				startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!,
				endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: tomorrow)!,
				isAllDay: false,
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Quarterly Planning",
				startDate: calendar.date(
					bySettingHour: 10, minute: 0, second: 0, of: dayAfterTomorrow)!,
				endDate: calendar.date(
					bySettingHour: 12, minute: 0, second: 0, of: dayAfterTomorrow)!,
				isAllDay: false,
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Team Lunch",
				startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day3)!,
				endDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: day3)!,
				isAllDay: false,
				location: "The Noodle Place",
				calendarColor: .orange
			),
			WidgetEvent(
				title: "Dentist Appointment",
				startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day5)!,
				endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day5)!,
				isAllDay: false,
				calendarColor: .red
			),
		]
	}
}
