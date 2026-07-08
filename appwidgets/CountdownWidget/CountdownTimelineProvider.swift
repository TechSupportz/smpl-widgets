//
//  CountdownTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 06/07/26.
//

import AppIntents
import Foundation
import WidgetKit

struct CountdownTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = CountdownEntry
	typealias Intent = CountdownConfigurationIntent

	func placeholder(in context: Context) -> CountdownEntry {
		.preview
	}

	func snapshot(
		for configuration: CountdownConfigurationIntent,
		in context: Context
	) async -> CountdownEntry {
		context.isPreview ? .preview : entry(for: configuration, at: .now)
	}

	func timeline(
		for configuration: CountdownConfigurationIntent,
		in context: Context
	) async -> Timeline<CountdownEntry> {
		let currentDate = Date()
		let entry = entry(for: configuration, at: currentDate)
		let policy = reloadPolicy(for: entry.state, currentDate: currentDate)

		return Timeline(entries: [entry], policy: policy)
	}

	private func entry(
		for configuration: CountdownConfigurationIntent,
		at currentDate: Date
	) -> CountdownEntry {
		let startDate = configuration.resolvedStartDate(relativeTo: currentDate)
		let state = CountdownCalculator.state(
			title: configuration.displayTitle,
			startDate: startDate,
			endDate: configuration.resolvedEndDate(),
			currentDate: currentDate
		)

		return CountdownEntry(
			date: currentDate,
			state: state,
			accent: configuration.resolvedAccent
		)
	}

	private func reloadPolicy(
		for state: CountdownState,
		currentDate: Date
	) -> TimelineReloadPolicy {
		switch state {
		case .unconfigured, .invalid(.endBeforeStart):
			.never
		case .invalid(.futureStartDate):
			.after(currentDate.startOfNextDay)
		case .configured(_, let remainingDays, _):
			remainingDays == 0 ? .never : .after(currentDate.startOfNextDay)
		}
	}
}
