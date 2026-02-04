//
//  EventTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import EventKit
import SwiftUI
import WidgetKit
import os

struct EventTimelineProvider: TimelineProvider {
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets.appwidgets", category: "EventWidget")
	private let eventStore = EKEventStore()

	func placeholder(in context: Context) -> EventEntry {
		return EventEntry(date: Date(), events: Self.sampleEvents, authState: .authorized)
	}

	func getSnapshot(
		in context: Context,
		completion: @escaping @Sendable (EventEntry) -> Void
	) {

		if context.isPreview {
			completion(EventEntry(date: Date(), events: Self.sampleWeekEvents, authState: .authorized))
			return
		}

		let status = EKEventStore.authorizationStatus(for: .event)
		let authState = CalendarAuthState(from: status)

		if authState == .authorized {
			let weekEvents = fetchWeekEvents()
			completion(EventEntry(date: Date(), events: weekEvents, authState: authState))
		} else {
			completion(EventEntry(date: Date(), events: [], authState: authState))
		}
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<EventEntry>) -> Void
	) {
		let currentDate = Date()

		let status = EKEventStore.authorizationStatus(for: .event)
		let authState = CalendarAuthState(from: status)

		switch authState {
		case .authorized:
			let weekEvents = fetchWeekEvents()

			// Calculate update dates based on event start/end times and 10-min post-end buffer
			var updateDates: Set<Date> = []

			// Always refresh at the start of the next day
			let calendar = Calendar.current
			let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate))!
			updateDates.insert(startOfNextDay)

			// Add granular updates for event state changes from all week events
			for event in weekEvents {
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
			let futureUpdates = updateDates
				.filter { $0 > currentDate }
				.sorted()

			// Create entries for now and each future update time
			var entries: [EventEntry] = []

			// Entry for right now
			entries.append(EventEntry(date: currentDate, events: weekEvents, authState: authState))

			// Entries for future updates
			for updateDate in futureUpdates {
				entries.append(EventEntry(date: updateDate, events: weekEvents, authState: authState))
			}

			// Use .atEnd policy so widget requests new timeline after the last entry
			completion(Timeline(entries: entries, policy: .atEnd))

		case .notDetermined:
			let entry = EventEntry(date: currentDate, events: [], authState: authState)
			// Check again in 15 minutes in case user grants permission
			let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
			completion(Timeline(entries: [entry], policy: .after(nextUpdate)))

		case .denied, .restricted:
			let entry = EventEntry(date: currentDate, events: [], authState: authState)
			// Check again in 1 hour in case user changes settings
			let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
			completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
		}
	}

	private func fetchTodayEvents() -> [WidgetEvent] {
		let calendar = Calendar.current
		let now = Date()
		let startOfDay = calendar.startOfDay(for: now)
		let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

		let predicate = eventStore.predicateForEvents(
			withStart: startOfDay,
			end: endOfDay,
			calendars: nil
		)

		let ekEvents = eventStore.events(matching: predicate)

		return ekEvents.map { WidgetEvent(from: $0) }
	}

	private func fetchWeekEvents() -> [WidgetEvent] {
		let calendar = Calendar.current
		let now = Date()
		let startOfDay = calendar.startOfDay(for: now)
		let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfDay)!

		let predicate = eventStore.predicateForEvents(
			withStart: startOfDay,
			end: endOfWeek,
			calendars: nil
		)

		let ekEvents = eventStore.events(matching: predicate)
		return ekEvents.map { WidgetEvent(from: $0) }
	}

	// MARK: - Sample Data for Previews

	static var sampleEvents: [WidgetEvent] {
		let now = Date()
		let calendar = Calendar.current

		return [
			WidgetEvent(
				title: "Team Standup",
				startDate: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 22, minute: 30, second: 0, of: now)!,
				isAllDay: true,
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Lunch with Alex",
				startDate: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				calendarColor: .green
			),
			WidgetEvent(
				title: "Project Review",
				startDate: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				location: nil,
				calendarColor: .orange
			),
			WidgetEvent(
				title: "Client Meeting",
				startDate: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				location: "Conference Room A",
				calendarColor: .purple
			),
			WidgetEvent(
				title: "Design Sync",
				startDate: calendar.date(bySettingHour: 23, minute: 30, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 23, minute: 45, second: 0, of: now)!,
				isAllDay: false,
				location: "Zoom",
				calendarColor: .red
			),
		]
	}

	static var sampleWeekEvents: [WidgetEvent] {
		let now = Date()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: now)
		let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
		let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!

		return sampleEvents + [
			WidgetEvent(
				title: "Morning Jog",
				startDate: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow)!,
				endDate: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)!,
				isAllDay: false,
				calendarColor: .green
			),
			WidgetEvent(
				title: "Quarterly Planning",
				startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!,
				endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow)!,
				isAllDay: false,
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Dentist Appointment",
				startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dayAfterTomorrow)!,
				endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayAfterTomorrow)!,
				isAllDay: false,
				calendarColor: .red
			),
		]
	}
}
