//
//  EventWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 01/13/26.
//

import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct EventWidgetView: View {
	var entry: EventEntry
	@Environment(\.widgetFamily) var widgetFamily

	private struct EventSectionData: Identifiable {
		let id: String
		let header: String
		let events: [WidgetEvent]
	}

	private struct LargeTodayLayout {
		let allDayEvents: [WidgetEvent]
		let timedSections: [EventSectionData]

		var fittedEventCount: Int {
			allDayEvents.count + timedSections.reduce(0) { $0 + $1.events.count }
		}
	}

	private enum LayoutMetrics {
		static let eventSpacing: CGFloat = 6
		static let sectionSpacing: CGFloat = 6
		static let sectionHeaderToEventsSpacing: CGFloat = 4
		static let titleToMetadataSpacing: CGFloat = 2
		static let metadataLineSpacing: CGFloat = 2
		static let timedRowVerticalPadding: CGFloat = 1
		static let allDayRowVerticalPadding: CGFloat = 2

		#if canImport(UIKit)
			static let titleLineHeight = ceil(UIFont.systemFont(ofSize: 16, weight: .semibold).lineHeight)
			static let metadataLineHeight = ceil(UIFont.systemFont(ofSize: 12, weight: .regular).lineHeight)
			static let sectionHeaderHeight = ceil(UIFont.systemFont(ofSize: 10, weight: .medium).lineHeight)
		#else
			static let titleLineHeight: CGFloat = 20
			static let metadataLineHeight: CGFloat = 16
			static let sectionHeaderHeight: CGFloat = 13
		#endif
	}

	var body: some View {
		VStack(spacing: 0) {
			if entry.isAuthorized {
				authorizedLayoutView
			} else {
				permissionRequiredView
			}
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
		let fittedLayout = fittingLargeTodayLayout(in: height)

		return columnContentView {
			if fittedLayout.fittedEventCount == 0 {
				centeredSecondaryMessage("All done\nfor today", fontSize: 18, trailingPadding: 16)
			} else {
				VStack(alignment: .leading, spacing: 0) {
					if !fittedLayout.allDayEvents.isEmpty {
						eventRowsView(fittedLayout.allDayEvents)
					}

					if !fittedLayout.timedSections.isEmpty {
						sectionListView(fittedLayout.timedSections)
							.padding(.top, fittedLayout.allDayEvents.isEmpty ? 0 : sectionSpacing)
					}
				}
			}
		}
	}

	private func largeRightColumn(height: CGFloat) -> some View {
		let overflowEvents = Array(
			entry.todayDisplayableEvents.dropFirst(fittingLargeTodayLayout(in: height).fittedEventCount)
		)
		return upcomingEventsColumn(height: height, overflowEvents: overflowEvents)
	}

	private func fittingLargeTodayLayout(in height: CGFloat) -> LargeTodayLayout {
		let allDayEvents = entry.todayDisplayableEvents.filter {
			$0.isAllDay || $0.spansMultipleDays()
		}
		let timedEvents = entry.todayDisplayableEvents.filter {
			!$0.isAllDay && !$0.spansMultipleDays()
		}
		let fittedAllDayEvents = fittingEvents(in: height, from: allDayEvents)
		let fittedSections = fittingSections(
			in: height - fittedAllDayEvents.usedHeight,
			from: hourlySections(from: timedEvents),
			hasLeadingContent: !fittedAllDayEvents.events.isEmpty
		)

		return LargeTodayLayout(
			allDayEvents: fittedAllDayEvents.events,
			timedSections: fittedSections
		)
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
		let formatter = DateFormatter()
		formatter.locale = .autoupdatingCurrent
		formatter.setLocalizedDateFormatFromTemplate("j:mm")

		var components = DateComponents()
		components.hour = hour
		components.minute = 0

		guard let date = Calendar.autoupdatingCurrent.date(from: components) else {
			return String(format: "%02d:00", hour)
		}

		return formatter.string(from: date)
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
		VStack(alignment: .leading, spacing: LayoutMetrics.sectionHeaderToEventsSpacing) {
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
				.frame(height: sectionHeaderHeight, alignment: .leading)

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

	private var eventSpacing: CGFloat { LayoutMetrics.eventSpacing }
	private var sectionHeaderHeight: CGFloat { LayoutMetrics.sectionHeaderHeight }
	private var sectionSpacing: CGFloat { LayoutMetrics.sectionSpacing }

	private func fittingEvents(
		in availableHeight: CGFloat,
		from events: [WidgetEvent]
	) -> (events: [WidgetEvent], usedHeight: CGFloat) {
		guard availableHeight > 0 else {
			return (events: [], usedHeight: 0)
		}

		var usedHeight: CGFloat = 0
		var result: [WidgetEvent] = []

		for event in events {
			let rowHeight = rowHeight(for: event)
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
		guard availableHeight > 0 else {
			return []
		}

		var remainingHeight = availableHeight
		var result: [EventSectionData] = []

		for section in sections {
			let spacingBefore = (hasLeadingContent || !result.isEmpty) ? sectionSpacing : 0

			if remainingHeight < spacingBefore + sectionHeaderHeight {
				break
			}

			let fittedEvents = fittingEvents(
				in: remainingHeight
					- spacingBefore
					- sectionHeaderHeight
					- LayoutMetrics.sectionHeaderToEventsSpacing,
				from: section.events
			)

			guard !fittedEvents.events.isEmpty else {
				break
			}

			remainingHeight -=
				spacingBefore
				+ sectionHeaderHeight
				+ LayoutMetrics.sectionHeaderToEventsSpacing
				+ fittedEvents.usedHeight
			result.append(
				EventSectionData(
					id: section.id,
					header: section.header,
					events: fittedEvents.events
				)
			)
		}

		return result
	}

	private func upcomingEventsColumn(height: CGFloat, overflowEvents: [WidgetEvent]) -> some View {
		let fittedOverflowEvents = fittingEvents(in: height, from: overflowEvents)
		let fittedDaySections = fittingSections(
			in: max(height - fittedOverflowEvents.usedHeight, 0),
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
					HStack(spacing: 8) {
						left(geometry.size.height)
						right(geometry.size.height)
					}
				}
			}
		}
	}

	private func rowHeight(for event: WidgetEvent) -> CGFloat {
		let metadataLineCount = eventMetadataLineCount(for: event)
		let metadataHeight: CGFloat

		if metadataLineCount == 0 {
			metadataHeight = 0
		} else {
			metadataHeight = LayoutMetrics.titleToMetadataSpacing
				+ (CGFloat(metadataLineCount) * LayoutMetrics.metadataLineHeight)
				+ (CGFloat(max(metadataLineCount - 1, 0)) * LayoutMetrics.metadataLineSpacing)
		}

		return LayoutMetrics.titleLineHeight
			+ metadataHeight
			+ (eventRowVerticalPadding(for: event) * 2)
	}

	private func eventRowVerticalPadding(for event: WidgetEvent) -> CGFloat {
		event.isAllDay || event.spansMultipleDays()
			? LayoutMetrics.allDayRowVerticalPadding
			: LayoutMetrics.timedRowVerticalPadding
	}

	private func eventMetadataLineCount(for event: WidgetEvent) -> Int {
		let secondaryTextCount = eventSecondaryText(for: event) == nil ? 0 : 1
		let locationCount = eventLocationText(for: event) == nil ? 0 : 1
		return secondaryTextCount + locationCount
	}

	private func eventLocationText(for event: WidgetEvent) -> String? {
		guard let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines),
			!location.isEmpty
		else {
			return nil
		}

		return location
	}

	private func eventRow(_ event: WidgetEvent) -> some View {
		let isAllDayStyle = event.isAllDay || event.spansMultipleDays()
		let secondaryText = eventSecondaryText(for: event)
		let location = eventLocationText(for: event)

		return HStack(alignment: .center, spacing: 6) {
			Capsule()
				.fill(event.pillColor(at: entry.date))
				.frame(width: 4)
				.frame(maxHeight: .infinity)

			VStack(alignment: .leading, spacing: 2) {
				Text(event.title)
					.font(.system(size: 16, weight: .semibold))
					.fontWidth(.compressed)
					.lineLimit(1)
					.frame(height: LayoutMetrics.titleLineHeight, alignment: .leading)

				if secondaryText != nil || location != nil {
					VStack(alignment: .leading, spacing: LayoutMetrics.metadataLineSpacing) {
						if let secondaryText {
							HStack(spacing: 2) {
								Image(systemName: eventSecondaryIcon(for: event))
								Text(secondaryText)
									.font(.system(size: 12))
									.fixedSize(horizontal: true, vertical: false)
							}
							.frame(height: LayoutMetrics.metadataLineHeight, alignment: .leading)
						}

						if let location {
							HStack(spacing: 2) {
								Image(systemName: "mappin.and.ellipse")
								Text(location)
									.font(.system(size: 12))
									.lineLimit(1)
							}
							.frame(height: LayoutMetrics.metadataLineHeight, alignment: .leading)
						}
					}
					.font(.system(size: 8, weight: .regular))
					.fontWidth(.condensed)
				}
			}
			.padding(.vertical, eventRowVerticalPadding(for: event))
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		}
		.frame(height: rowHeight(for: event), alignment: .top)
		.background {
			if isAllDayStyle {
				RoundedRectangle(cornerRadius: 4)
					.fill(event.calendarColor.opacity(0.1))
			}
		}
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
				.foregroundStyle(.secondary)

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
