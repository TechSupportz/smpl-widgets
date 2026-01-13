//
//  EventTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import EventKit
import os
import SwiftUI
import WidgetKit

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
			completion(EventEntry(date: Date(), events: Self.sampleEvents, authState: .authorized))
			return
		}

		let status = EKEventStore.authorizationStatus(for: .event)
		let authState = CalendarAuthState(from: status)
		logger.info("📸 Snapshot auth status: \(status.rawValue)")

		if authState == .authorized {
			let events = fetchTodayEvents()
			logger.info("📸 Snapshot completed with \(events.count) events")
			completion(EventEntry(date: Date(), events: events, authState: authState))
		} else {
			logger.warning("📸 Snapshot: Calendar not authorized")
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
		logger.info("🔐 Calendar authorization status: \(status.rawValue) -> \(String(describing: authState))")

		switch authState {
		case .authorized:
			let events = fetchTodayEvents()
			let entry = EventEntry(date: currentDate, events: events, authState: authState)

			// Refresh at the start of the next day
			let nextUpdate = currentDate.startOfNextDay
			logger.info("⏰ Timeline created with \(events.count) events")
			logger.info("⏰ Next update scheduled for: \(nextUpdate)")

			completion(Timeline(entries: [entry], policy: .after(nextUpdate)))

		case .notDetermined:
			logger.warning("⚠️ Calendar access not determined. User must grant permission in main app.")
			let entry = EventEntry(date: currentDate, events: [], authState: authState)
			// Check again in 15 minutes in case user grants permission
			let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
			completion(Timeline(entries: [entry], policy: .after(nextUpdate)))

		case .denied, .restricted:
			logger.warning("❌ Calendar access denied/restricted. User must enable in Settings.")
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

		logger.debug("📅 Fetching events for today: \(startOfDay) to \(endOfDay)")

		let predicate = eventStore.predicateForEvents(
			withStart: startOfDay,
			end: endOfDay,
			calendars: nil
		)

		let ekEvents = eventStore.events(matching: predicate)
		logger.info("📅 Found \(ekEvents.count) events")

		if !ekEvents.isEmpty {
			let eventTitles = ekEvents.map { $0.title ?? "Untitled" }
			logger.debug("📅 Event titles: \(eventTitles)")
		}

		return ekEvents.map { WidgetEvent(from: $0) }
	}

	// MARK: - Sample Data for Previews

	static var sampleEvents: [WidgetEvent] {
		let now = Date()
		let calendar = Calendar.current

		return [
			WidgetEvent(
				title: "Team Standup",
				startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now)!,
				isAllDay: true,
				location: "Zoom",
				calendarColor: .blue
			),
			WidgetEvent(
				title: "Lunch with Alex",
				startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				location: "Cafe Central",
				calendarColor: .green
			),
			WidgetEvent(
				title: "Project Review",
				startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now)!,
				endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now)!,
				isAllDay: false,
				location: nil,
				calendarColor: .orange
			),
		]
	}
}
