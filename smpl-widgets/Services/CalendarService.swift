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

class CalendarService: ObservableObject {
	private let eventStore = EKEventStore()
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "CalendarService")

	@Published var authorizationStatus: EKAuthorizationStatus

	init() {
		self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
	}

	/// Request full access to calendar events
	func requestPermission() {
		eventStore.requestFullAccessToEvents { [weak self] _, error in
			DispatchQueue.main.async {
				if let error = error {
					self?.logger.error("❌ Calendar permission error: \(error.localizedDescription)")
				}

				let newStatus = EKEventStore.authorizationStatus(for: .event)
				self?.authorizationStatus = newStatus
			}
		}
	}

	/// Refresh the current authorization status
	func refreshStatus() {
		let newStatus = EKEventStore.authorizationStatus(for: .event)
		if newStatus != authorizationStatus {
			authorizationStatus = newStatus
		}
	}

	/// Check if calendar access is authorized
	var isAuthorized: Bool {
		authorizationStatus == .fullAccess
	}

	/// Check if permission has been denied
	var isDenied: Bool {
		authorizationStatus == .denied || authorizationStatus == .restricted
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
		case .fullAccess, .authorized:
			return "Enabled for event widgets"
		case .writeOnly:
			return "Write Only - Need Full Access"
		@unknown default:
			return "Unknown"
		}
	}

	var iconName: String {
		switch self {
		case .fullAccess, .authorized:
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
		case .fullAccess, .authorized:
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
