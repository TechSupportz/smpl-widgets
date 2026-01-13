//
//  EventWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import SwiftUI
import WidgetKit

struct EventWidgetView: View {
	var entry: EventEntry

	private let maxEventsToShow = 2

	var body: some View {
		VStack(spacing: 0) {
			if entry.isAuthorized {
				if entry.hasEvents {
					eventsListView
				} else {
					emptyStateView
				}
			} else {
				permissionRequiredView
			}

			Spacer(minLength: 0)

			bottomBar
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.widgetURL(URL(string: "smplwidgets://events"))
	}

	// MARK: - Events List View

	private var eventsListView: some View {
		VStack(alignment: .leading, spacing: 6) {
			ForEach(entry.sortedEvents.prefix(maxEventsToShow)) { event in
				eventRow(event)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.fixedSize(horizontal: false, vertical: true)
	}

	private func eventRow(_ event: WidgetEvent) -> some View {
		HStack(alignment: .center, spacing: 6) {
			Capsule()
				.fill(event.calendarColor)
				.frame(width: 4)
				.frame(maxHeight: .infinity)

			VStack(alignment: .leading, spacing: 2) {
				Text(event.title)
					.font(.system(size: 16, weight: .semibold))
					.fontWidth(.compressed)
					.lineLimit(1)

				VStack(alignment: .leading, spacing: 2) {
					if !event.isAllDay {
						HStack(spacing: 2) {
							Image(systemName: "clock")
							Text(timeRangeText(for: event))
								.font(.system(size: 12))
								.fixedSize(horizontal: true, vertical: false)
						}
					}

					if let location = event.location, !location.isEmpty {
						HStack(spacing: 2) {
							Image(systemName: "mappin.and.ellipse.circle.fill")
							Text(location)
								.font(.system(size: 12))
								.lineLimit(1)
						}
					}
				}
				.font(.system(size: 8, weight: .regular))
				.fontWidth(.condensed)
			}
			.padding(.vertical, 1)
		}
		.fixedSize(horizontal: false, vertical: true)
	}

	private func timeRangeText(for event: WidgetEvent) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		let start = formatter.string(from: event.startDate)
		let end = formatter.string(from: event.endDate)
		return "\(start) - \(end)"
	}

	// MARK: - Empty State View (Authorized but no events)

	private var emptyStateView: some View {
		VStack {
			Spacer()
			Text("nothing to\nsee here")
				.font(.system(size: 20, weight: .regular, design: .default))
				.multilineTextAlignment(.center)
			Spacer()
		}
		.frame(maxWidth: .infinity)
	}

	// MARK: - Permission Required View

	private var permissionRequiredView: some View {
		VStack(spacing: 6) {
			Spacer()

			Image(systemName: "calendar.badge.exclamationmark")
				.font(.system(size: 32))
				.foregroundStyle(.secondary)

			Text("Tap to open smpl.")
				.font(.system(size: 10, weight: .regular))
				.foregroundStyle(.tertiary)

			Spacer()
		}
		.frame(maxWidth: .infinity)
	}

	// MARK: - Bottom Bar

	private var bottomBar: some View {
		HStack(alignment: .bottom) {
			Text(formattedDate)
				.font(.system(size: 12, weight: .regular, design: .monospaced))
				.italic()
			Spacer()
			if entry.isAuthorized {
				if entry.hasEvents {
					Text(String(format: "%02d", entry.eventCount))
						.font(.system(size: 16, weight: .regular, design: .monospaced))
						.foregroundStyle(.red)
				} else {
					Image(systemName: "eyes")
						.font(.system(size: 16))
				}
			} else {
				Image(systemName: "exclamationmark.triangle")
					.font(.system(size: 16))
					.foregroundStyle(.orange)
			}
		}
	}

	private var formattedDate: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd.MM.yy"
		return formatter.string(from: entry.date)
	}
}

// MARK: - Previews

#Preview("With Events", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: EventTimelineProvider.sampleEvents, authState: .authorized)
}

#Preview("Empty State", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .authorized)
}

#Preview("Permission Required", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .denied)
}

#Preview("Not Determined", as: .systemSmall) {
	EventWidget()
} timeline: {
	EventEntry(date: .now, events: [], authState: .notDetermined)
}
