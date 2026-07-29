//
//  CalendarService.swift
//  smpl-widgets
//
//  Created by Nitish on 01/13/26.
//

import Combine
import EventKit
import SwiftUI
import os

struct CalendarSelectionOption: Identifiable, Equatable {
	let id: String
	let title: String
	let sourceTitle: String
	let color: Color

	var sourceDisplayName: String? {
		guard !sourceTitle.isEmpty && sourceTitle != title else {
			return nil
		}

		return sourceTitle
	}

	init(calendar: EKCalendar) {
		self.id = calendar.calendarIdentifier
		self.title = calendar.title
		self.sourceTitle = calendar.source.title

		if let cgColor = calendar.cgColor {
			self.color = Color(cgColor: cgColor)
		} else {
			self.color = .blue
		}
	}
}

final class CalendarService: ObservableObject {
	private let eventStore = EKEventStore()
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "CalendarService")

	@Published var authorizationStatus: EKAuthorizationStatus
	@Published var calendars: [CalendarSelectionOption] = []

	init() {
		self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
		refreshCalendars()
	}

	/// Request full access to calendar events
	func requestPermission() {
		Task {
			do {
				_ = try await eventStore.requestFullAccessToEvents()
			} catch {
				logger.error("Calendar permission error: \(error.localizedDescription)")
			}

			refreshStatus()
		}
	}

	/// Refresh the current authorization status
	func refreshStatus() {
		let newStatus = EKEventStore.authorizationStatus(for: .event)
		if newStatus != authorizationStatus {
			authorizationStatus = newStatus
		}
		refreshCalendars()
	}

	/// Check if calendar access is authorized
	var isAuthorized: Bool {
		authorizationStatus == .fullAccess
	}

	/// Check if permission has been denied
	var isDenied: Bool {
		authorizationStatus == .denied || authorizationStatus == .restricted
	}

	func refreshCalendars() {
		guard isAuthorized else {
			if !calendars.isEmpty {
				calendars = []
			}
			return
		}

		let sortedCalendars = eventStore.calendars(for: .event)
			.sorted { first, second in
				let titleComparison = first.title.localizedCaseInsensitiveCompare(second.title)

				if titleComparison == .orderedSame {
					return first.source.title.localizedCaseInsensitiveCompare(second.source.title)
						== .orderedAscending
				}

				return titleComparison == .orderedAscending
			}
		var availableCalendars: [CalendarSelectionOption] = []
		availableCalendars.reserveCapacity(sortedCalendars.count)

		for calendar in sortedCalendars {
			availableCalendars.append(CalendarSelectionOption(calendar: calendar))
		}

		if calendars != availableCalendars {
			calendars = availableCalendars
		}
	}
}

// MARK: - Authorization Status Helpers

extension EKAuthorizationStatus {
	var displayName: String {
		switch self {
		case .notDetermined:
			return "Not Configured"
		case .restricted:
			return "Restricted by System"
		case .denied:
			return "Denied - Enable in Settings"
		case .fullAccess:
			return "Enabled for event widgets"
		case .writeOnly:
			return "Write Only - Need Full Access"
		@unknown default:
			return "Unknown"
		}
	}

	var iconName: String {
		switch self {
		case .fullAccess:
			return "calendar"
		case .denied, .restricted:
			return "calendar.badge.exclamationmark"
		case .notDetermined:
			return "calendar.badge.plus"
		case .writeOnly:
			return "calendar.badge.minus"
		@unknown default:
			return "calendar"
		}
	}

	var iconColor: Color {
		switch self {
		case .fullAccess:
			return .blue
		case .denied, .restricted:
			return .red
		case .notDetermined:
			return .orange
		case .writeOnly:
			return .yellow
		@unknown default:
			return .gray
		}
	}
}
