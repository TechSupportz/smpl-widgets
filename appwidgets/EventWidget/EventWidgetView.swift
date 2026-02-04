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
	@Environment(\.widgetFamily) var widgetFamily

	var body: some View {
		VStack(spacing: 0) {
			if entry.isAuthorized {
				if widgetFamily == .systemMedium {
					mediumLayoutView
				} else {
					smallLayoutView
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
		if entry.isAuthorized {
			return URL(string: "smplwidgets://events")!
		} else {
			return URL(string: "smplwidgets://permissions")!
		}
	}

	// MARK: - Small Layout

	private var smallLayoutView: some View {
		Group {
			if entry.hasDisplayableEvents {
				smallEventsListView
			} else {
				emptyStateView
			}
		}
	}

	private var smallEventsListView: some View {
		GeometryReader { geometry in
			let eventsToShow = eventsToDisplay(
				in: geometry.size.height, from: entry.displayableEvents)

			VStack(alignment: .leading, spacing: eventSpacing) {
				ForEach(eventsToShow) { event in
					eventRow(event)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.clipped()
	}

	// MARK: - Medium Layout

	private var mediumLayoutView: some View {
		GeometryReader { geometry in
			HStack(spacing: 0) {
				// Left column: Today's events
				mediumLeftColumn(height: geometry.size.height)
				// Right column: Overflow + upcoming events
				mediumRightColumn(height: geometry.size.height)
			}
		}
	}

	private func mediumLeftColumn(height: CGFloat) -> some View {
		let todayEvents = entry.todayDisplayableEvents
		let eventsToShow = eventsToDisplay(in: height, from: todayEvents)

		return VStack(alignment: .leading, spacing: eventSpacing) {
			ForEach(eventsToShow) { event in
				eventRow(event)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.clipped()
	}

	private func mediumRightColumn(height: CGFloat) -> some View {
		let todayEvents = entry.todayDisplayableEvents
		let leftEvents = eventsToDisplay(in: height, from: todayEvents)
		let overflowEvents = Array(todayEvents.dropFirst(leftEvents.count))
		let upcomingDays = entry.upcomingDaysEvents

		// Calculate what fits in the right column
		let rightContent = calculateRightColumnContent(
			height: height,
			overflowEvents: overflowEvents,
			upcomingDays: upcomingDays
		)

		return VStack(alignment: .leading, spacing: eventSpacing) {
			// Show overflow from today first (without date header)
			ForEach(rightContent.overflowEvents) { event in
				eventRow(event)
			}

			// Show upcoming days that fit
			ForEach(rightContent.days.indices, id: \.self) { index in
				let dayData = rightContent.days[index]
				daySection(date: dayData.date, events: dayData.events)
			}

			// Empty state for the week
			if rightContent.overflowEvents.isEmpty && rightContent.days.isEmpty {
				Spacer()
				Text("Nothing to see here")
					.font(.system(size: 14))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.frame(maxWidth: .infinity)
				Spacer()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.clipped()
	}

	private func calculateRightColumnContent(
		height: CGFloat,
		overflowEvents: [WidgetEvent],
		upcomingDays: [(date: Date, events: [WidgetEvent])]
	) -> (overflowEvents: [WidgetEvent], days: [(date: Date, events: [WidgetEvent])]) {
		var remainingHeight = height
		var selectedOverflowEvents: [WidgetEvent] = []
		var selectedDays: [(date: Date, events: [WidgetEvent])] = []

		// First, add overflow events from today (no date header needed)
		for event in overflowEvents {
			let rowHeight = estimatedRowHeight(for: event)
			let spacing = selectedOverflowEvents.isEmpty ? 0 : eventSpacing

			if remainingHeight >= spacing + rowHeight {
				remainingHeight -= (spacing + rowHeight)
				selectedOverflowEvents.append(event)
			} else {
				break
			}
		}

		// Then, add upcoming days with their date headers
		let dateHeaderHeight: CGFloat = 10 // Approximate height of date header
		let sectionSpacing: CGFloat = 6 // Spacing between day sections

		for dayData in upcomingDays {
			// Check if we can fit the date header
			let needsSectionSpacing = !selectedOverflowEvents.isEmpty || !selectedDays.isEmpty
			let spacingBeforeHeader = needsSectionSpacing ? sectionSpacing : 0

			if remainingHeight < spacingBeforeHeader + dateHeaderHeight {
				break
			}

			// Calculate how many events from this day can fit
			var dayEventsToShow: [WidgetEvent] = []
			var tempHeight = remainingHeight - spacingBeforeHeader - dateHeaderHeight

			for event in dayData.events {
				let rowHeight = estimatedRowHeight(for: event)
				let eventSpacing = dayEventsToShow.isEmpty ? 0 : eventSpacing

				if tempHeight >= eventSpacing + rowHeight {
					tempHeight -= (eventSpacing + rowHeight)
					dayEventsToShow.append(event)
				} else {
					break
				}
			}

			// Only add this day if we can show at least one event
			if !dayEventsToShow.isEmpty {
				remainingHeight = tempHeight
				selectedDays.append((date: dayData.date, events: dayEventsToShow))
			}
		}

		return (overflowEvents: selectedOverflowEvents, days: selectedDays)
	}

	private func daySection(date: Date, events: [WidgetEvent]) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			// Date header with divider
			HStack(spacing: 4) {
				Text(dateHeaderText(for: date))
					.font(.system(size: 10, weight: .medium))
					.italic()
					.foregroundStyle(.primary)

				Rectangle()
					.fill(Color.gray.opacity(0.4))
					.frame(height: 1)
			}

			// Events for this day
			VStack(alignment: .leading, spacing: eventSpacing) {
				ForEach(events) { event in
					eventRow(event)
				}
			}
		}
	}

	private func dateHeaderText(for date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd.MM.yy"
		return formatter.string(from: date)
	}

	// MARK: - Events List Logic

	private let eventSpacing: CGFloat = 6

	private func eventsToDisplay(
		in availableHeight: CGFloat, from events: [WidgetEvent]
	) -> [WidgetEvent] {
		var totalHeight: CGFloat = 0
		var result: [WidgetEvent] = []

		for event in events {
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

	// MARK: - Empty State View

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
		HStack(alignment: .firstTextBaseline) {
			Text(widgetFamily == .systemMedium ? "events this week." : "events today.")
				.font(.system(size: 12))
				.fontWeight(.medium)
				.fontWidth(.condensed)
				.foregroundStyle(.secondary)
			Spacer()
			if entry.isAuthorized {
				if entry.hasEvents {
					Text(
						String(
							format: "%02d",
							entry.eventCount
						)
					)
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
