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

	private struct EventSectionData: Identifiable {
		let id: String
		let header: String
		let events: [WidgetEvent]
	}

	var body: some View {
		VStack(spacing: 0) {
			if entry.isAuthorized {
				authorizedLayoutView
			} else {
				permissionRequiredView
			}
			Spacer()
			bottomBar
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.widgetURL(widgetURL)
	}

	@ViewBuilder
	private var authorizedLayoutView: some View {
		switch widgetFamily {
		case .systemLarge:
			largeLayoutView
		case .systemMedium:
			mediumLayoutView
		default:
			smallLayoutView
		}
	}

	private var widgetURL: URL {
		URL(string: entry.isAuthorized ? "smplwidgets://events" : "smplwidgets://permissions")!
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
			let eventsToShow = fittingEvents(
				in: geometry.size.height,
				from: entry.displayableEvents
			).events

			columnContentView {
				eventRowsView(eventsToShow)
			}
		}
		.clipped()
	}

	// MARK: - Medium Layout

	private var mediumLayoutView: some View {
		let todayEvents = entry.todayDisplayableEvents
		let hasUpcomingEvents = !entry.upcomingDaysEvents.isEmpty

		return twoColumnLayoutView(isEmpty: todayEvents.isEmpty && !hasUpcomingEvents) { height in
			mediumLeftColumn(height: height)
		} right: { height in
			mediumRightColumn(height: height)
		}
	}

	private func mediumLeftColumn(height: CGFloat) -> some View {
		let eventsToShow = fittingEvents(in: height, from: entry.todayDisplayableEvents).events

		return columnContentView {
			if eventsToShow.isEmpty {
				centeredSecondaryMessage("All done\nfor today", fontSize: 18, trailingPadding: 16)
			} else {
				eventRowsView(eventsToShow)
			}
		}
	}

	private func mediumRightColumn(height: CGFloat) -> some View {
		let leftEvents = fittingEvents(in: height, from: entry.todayDisplayableEvents).events
		let overflowEvents = Array(entry.todayDisplayableEvents.dropFirst(leftEvents.count))

		return upcomingEventsColumn(height: height, overflowEvents: overflowEvents)
	}

	// MARK: - Large Layout

	private var largeLayoutView: some View {
		return twoColumnLayoutView(
			isEmpty: entry.todayDisplayableEvents.isEmpty && entry.upcomingDaysEvents.isEmpty
		) { height in
			largeLeftColumn(height: height)
		} right: { height in
			largeRightColumn(height: height)
		}
	}

	private func largeLeftColumn(height: CGFloat) -> some View {
		let allDayEvents = entry.todayDisplayableEvents.filter {
			$0.isAllDay || $0.spansMultipleDays()
		}
		let timedEvents = entry.todayDisplayableEvents.filter {
			!$0.isAllDay && !$0.spansMultipleDays()
		}
		let fittedSections = fittingSections(
			in: height - totalHeight(for: allDayEvents),
			from: hourlySections(from: timedEvents),
			hasLeadingContent: !allDayEvents.isEmpty
		)

		return columnContentView {
			if allDayEvents.isEmpty && timedEvents.isEmpty {
				centeredSecondaryMessage("All done\nfor today", fontSize: 18, trailingPadding: 16)
			} else {
				VStack(alignment: .leading, spacing: 0) {
					if !allDayEvents.isEmpty {
						eventRowsView(allDayEvents)
					}

					if !fittedSections.isEmpty {
						sectionListView(fittedSections)
							.padding(.top, allDayEvents.isEmpty ? 0 : sectionSpacing)
					} else if timedEvents.isEmpty {
						Spacer()
					}
				}
			}
		}
	}

	private func largeRightColumn(height: CGFloat) -> some View {
		upcomingEventsColumn(height: height, overflowEvents: [])
	}

	// MARK: - Hour Timeline Helpers

	private func groupEventsByHour(_ events: [WidgetEvent]) -> [(hour: Int, events: [WidgetEvent])] {
		let calendar = Calendar.current
		let grouped = Dictionary(grouping: events) { event in
			calendar.component(.hour, from: event.startDate)
		}

		return grouped.sorted { $0.key < $1.key }
			.map { (hour: $0.key, events: $0.value.sorted { $0.startDate < $1.startDate }) }
	}

	private func hourlySections(from events: [WidgetEvent]) -> [EventSectionData] {
		groupEventsByHour(events).map { group in
			EventSectionData(
				id: "hour-\(group.hour)",
				header: hourHeaderText(for: group.hour),
				events: group.events
			)
		}
	}

	private func hourHeaderText(for hour: Int) -> String {
		String(format: "%02d:00", hour)
	}

	// MARK: - Shared Day Section

	private func upcomingDaySections(
		from upcomingDays: [(date: Date, events: [WidgetEvent])]
	) -> [EventSectionData] {
		upcomingDays.map { day in
			EventSectionData(
				id: "day-\(Int(day.date.timeIntervalSince1970))",
				header: dateHeaderText(for: day.date),
				events: day.events
			)
		}
	}

	private func sectionListView(_ sections: [EventSectionData]) -> some View {
		VStack(alignment: .leading, spacing: sectionSpacing) {
			ForEach(sections) { section in
				sectionView(section)
			}
		}
	}

	private func sectionView(_ section: EventSectionData) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			sectionHeaderView(section.header)
			eventRowsView(section.events)
		}
	}

	private func sectionHeaderView(_ title: String) -> some View {
		HStack(spacing: 4) {
			Text(title)
				.font(.system(size: 10, weight: .medium))
				.italic()
				.foregroundStyle(.primary)

			Rectangle()
				.fill(Color.gray.opacity(0.4))
				.frame(height: 1)
		}
	}

	private func dateHeaderText(for date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd.MM.yy"
		return formatter.string(from: date)
	}

	// MARK: - Events List Logic

	private let eventSpacing: CGFloat = 6
	private let sectionHeaderHeight: CGFloat = 10
	private let sectionSpacing: CGFloat = 6

	private func fittingEvents(
		in availableHeight: CGFloat,
		from events: [WidgetEvent]
	) -> (events: [WidgetEvent], usedHeight: CGFloat) {
		var usedHeight: CGFloat = 0
		var result: [WidgetEvent] = []

		for event in events {
			let rowHeight = estimatedRowHeight(for: event)
			let spacing = result.isEmpty ? 0 : eventSpacing

			if usedHeight + spacing + rowHeight <= availableHeight {
				usedHeight += spacing + rowHeight
				result.append(event)
			} else {
				break
			}
		}

		return (events: result, usedHeight: usedHeight)
	}

	private func fittingSections(
		in availableHeight: CGFloat,
		from sections: [EventSectionData],
		hasLeadingContent: Bool = false
	) -> [EventSectionData] {
		var remainingHeight = availableHeight
		var result: [EventSectionData] = []

		for section in sections {
			let spacingBefore = (hasLeadingContent || !result.isEmpty) ? sectionSpacing : 0

			if remainingHeight < spacingBefore + sectionHeaderHeight {
				break
			}

			let fittedEvents = fittingEvents(
				in: remainingHeight - spacingBefore - sectionHeaderHeight,
				from: section.events
			)

			if !fittedEvents.events.isEmpty {
				remainingHeight -= spacingBefore + sectionHeaderHeight + fittedEvents.usedHeight
				result.append(
					EventSectionData(
						id: section.id,
						header: section.header,
						events: fittedEvents.events
					)
				)
			}
		}

		return result
	}

	private func totalHeight(for events: [WidgetEvent]) -> CGFloat {
		fittingEvents(in: .greatestFiniteMagnitude, from: events).usedHeight
	}

	private func upcomingEventsColumn(height: CGFloat, overflowEvents: [WidgetEvent]) -> some View {
		let fittedOverflowEvents = fittingEvents(in: height, from: overflowEvents)
		let fittedDaySections = fittingSections(
			in: height - fittedOverflowEvents.usedHeight,
			from: upcomingDaySections(from: entry.upcomingDaysEvents),
			hasLeadingContent: !fittedOverflowEvents.events.isEmpty
		)

		return columnContentView {
			if fittedOverflowEvents.events.isEmpty && fittedDaySections.isEmpty {
				centeredSecondaryMessage("No upcoming events", fontSize: 14)
			} else {
				VStack(alignment: .leading, spacing: 0) {
					if !fittedOverflowEvents.events.isEmpty {
						eventRowsView(fittedOverflowEvents.events)
					}

					if !fittedDaySections.isEmpty {
						sectionListView(fittedDaySections)
							.padding(.top, fittedOverflowEvents.events.isEmpty ? 0 : sectionSpacing)
					}
				}
			}
		}
	}

	private func eventRowsView(_ events: [WidgetEvent]) -> some View {
		VStack(alignment: .leading, spacing: eventSpacing) {
			ForEach(events) { event in
				eventRow(event)
			}
		}
	}

	private func centeredSecondaryMessage(
		_ text: String,
		fontSize: CGFloat,
		trailingPadding: CGFloat = 0
	) -> some View {
		VStack {
			Spacer()
			Text(text)
				.font(.system(size: fontSize))
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.trailing, trailingPadding)
				.frame(maxWidth: .infinity)
			Spacer()
		}
	}

	private func columnContentView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		content()
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			.clipped()
	}

	private func twoColumnLayoutView<Left: View, Right: View>(
		isEmpty: Bool,
		@ViewBuilder left: @escaping (CGFloat) -> Left,
		@ViewBuilder right: @escaping (CGFloat) -> Right
	) -> some View {
		Group {
			if isEmpty {
				emptyStateView
			} else {
				GeometryReader { geometry in
					HStack(spacing: 0) {
						left(geometry.size.height)
						right(geometry.size.height)
					}
				}
			}
		}
	}

	private func estimatedRowHeight(for event: WidgetEvent) -> CGFloat {
		let titleHeight: CGFloat = 20
		let timeHeight: CGFloat = eventSecondaryText(for: event) == nil ? 0 : 16
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
					if let secondaryText = eventSecondaryText(for: event) {
						HStack(spacing: 2) {
							Image(systemName: eventSecondaryIcon(for: event))
							Text(secondaryText)
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

	private func eventSecondaryText(for event: WidgetEvent) -> String? {
		if event.spansMultipleDays() {
			return dateRangeText(for: event)
		}

		if !event.isAllDay {
			return timeRangeText(for: event)
		}

		return nil
	}

	private func eventSecondaryIcon(for event: WidgetEvent) -> String {
		event.spansMultipleDays() ? "calendar" : "clock"
	}

	private func dateRangeText(for event: WidgetEvent) -> String {
		let calendar = Calendar.current
		let startDay = calendar.startOfDay(for: event.startDate)
		let endDay = calendar.startOfDay(for: event.endDate.addingTimeInterval(-1))

		let formatter = DateFormatter()
		formatter.dateFormat = "d MMM"

		return "\(formatter.string(from: startDay)) - \(formatter.string(from: endDay))"
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
			Text(bottomBarLabel)
				.font(.system(size: 12))
				.fontWeight(.medium)
				.fontWidth(.condensed)
				.foregroundStyle(.secondary)
			Spacer()
			bottomBarStatusView
		}
		.padding(.vertical, -4)
	}

	private var bottomBarLabel: String {
		widgetFamily == .systemSmall ? "events today." : "events upcoming."
	}

	private var bottomBarCount: Int? {
		guard entry.isAuthorized else {
			return nil
		}

		switch widgetFamily {
		case .systemSmall:
			return entry.todayHasEvents ? entry.todayEventCount : nil
		default:
			return entry.hasEvents ? entry.eventCount : nil
		}
	}

	@ViewBuilder
	private var bottomBarStatusView: some View {
		if !entry.isAuthorized {
			Image(systemName: "exclamationmark.triangle")
				.font(.system(size: 12))
				.foregroundStyle(.orange)
		} else if let count = bottomBarCount {
			Text(String(format: "%02d", count))
				.font(.system(size: 12, weight: .regular, design: .monospaced))
				.foregroundStyle(.secondary)
		} else {
			Image(systemName: "eyes")
				.font(.system(size: 12))
		}
	}
}
