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

	var body: some View {
		VStack(spacing: 0) {
			if entry.isAuthorized {
				if entry.hasDisplayableEvents {
					eventsListView
				} else {
					emptyStateView
				}
			} else {
				permissionRequiredView
			}
			Spacer()
			bottomBar
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.widgetURL(widgetURL)
	}

	private var widgetURL: URL {
		// If not authorized, open smpl. app to grant permissions
		// Otherwise, open Calendar to today's events
		if entry.isAuthorized {
			return URL(string: "smplwidgets://events")!
		} else {
			return URL(string: "smplwidgets://permissions")!
		}
	}

	// MARK: - Events List View

	private let eventSpacing: CGFloat = 6

	private var eventsListView: some View {
		GeometryReader { geometry in
			let eventsToShow = eventsToDisplay(in: geometry.size.height)

			VStack(alignment: .leading, spacing: eventSpacing) {
				ForEach(eventsToShow) { event in
					eventRow(event)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.clipped()
	}

	private func eventsToDisplay(in availableHeight: CGFloat) -> [WidgetEvent] {
		let allEvents = entry.displayableEvents
		var totalHeight: CGFloat = 0
		var result: [WidgetEvent] = []

		for event in allEvents {
			let rowHeight = estimatedRowHeight(for: event)
			let spacing = result.isEmpty ? 0 : eventSpacing

			if totalHeight + spacing + rowHeight <= availableHeight {
				totalHeight += spacing + rowHeight
				result.append(event)
			} else {
				break
			}
		}

		return result
	}

	private func estimatedRowHeight(for event: WidgetEvent) -> CGFloat {
		let titleHeight: CGFloat = 20
		let timeHeight: CGFloat = event.isAllDay ? 0 : 16
		let locationHeight: CGFloat = (event.location != nil && !event.location!.isEmpty) ? 16 : 0
		let verticalPadding: CGFloat = 2

		return titleHeight + timeHeight + locationHeight + verticalPadding
	}

	private func eventRow(_ event: WidgetEvent) -> some View {
		HStack(alignment: .center, spacing: 6) {
			Capsule()
				.fill(event.pillColor(at: entry.date))
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
			Text("Events today")
				.font(.system(size: 12))
				.fontWeight(.medium)
				.fontWidth(.condensed)
				.foregroundStyle(.secondary)
			Spacer()
			if entry.isAuthorized {
				if entry.hasEvents {
					Text(String(format: "%02d", entry.eventCount))
						.font(.system(size: 12, weight: .regular, design: .monospaced))
						.foregroundStyle(.secondary)
				} else {
					Image(systemName: "eyes")
						.font(.system(size: 12))
				}
			} else {
				Image(systemName: "exclamationmark.triangle")
					.font(.system(size: 12))
					.foregroundStyle(.orange)
			}
		}
		.padding(.vertical, -4)
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
