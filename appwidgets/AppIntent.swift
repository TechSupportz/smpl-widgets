//
//  AppIntent.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import AppIntents
@preconcurrency import EventKit
import Foundation
import WidgetKit

struct ImageSlotEntity: AppEntity {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Saved Image")
	static var defaultQuery = ImageSlotEntityQuery()

	let id: String
	let displayName: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "\(displayName)")
	}

	init(id: String, displayName: String) {
		self.id = id
		self.displayName = displayName
	}

	init(slot: ImageSlotMetadata) {
		self.init(id: slot.id, displayName: slot.displayName)
	}
}

struct ImageSlotEntityQuery: EntityQuery {
	func entities(for identifiers: [String]) async throws -> [ImageSlotEntity] {
		let slotsByID = Dictionary(
			uniqueKeysWithValues: ImageWidgetStorage.shared.allSlots.map { ($0.id, $0) }
		)

		return identifiers.compactMap { identifier in
			guard let slot = slotsByID[identifier] else {
				return nil
			}

			return ImageSlotEntity(slot: slot)
		}
	}

	func suggestedEntities() async throws -> [ImageSlotEntity] {
		ImageWidgetStorage.shared.allSlots.map(ImageSlotEntity.init(slot:))
	}
}

struct CalendarEntity: AppEntity {
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Calendar")
	static var defaultQuery = CalendarEntityQuery()

	let id: String
	let displayName: String
	let sourceTitle: String

	var displayRepresentation: DisplayRepresentation {
		if sourceTitle.isEmpty || sourceTitle == displayName {
			return DisplayRepresentation(title: "\(displayName)")
		}

		return DisplayRepresentation(
			title: "\(displayName)",
			subtitle: "\(sourceTitle)"
		)
	}

	init(id: String, displayName: String, sourceTitle: String) {
		self.id = id
		self.displayName = displayName
		self.sourceTitle = sourceTitle
	}

	init(calendar: EKCalendar) {
		self.init(
			id: calendar.calendarIdentifier,
			displayName: calendar.title,
			sourceTitle: calendar.source.title
		)
	}
}

struct CalendarEntityQuery: EntityQuery {
	func entities(for identifiers: [String]) async throws -> [CalendarEntity] {
		let availableCalendars = await availableCalendars()
		let calendarsByID = Dictionary(
			uniqueKeysWithValues: availableCalendars.map { ($0.id, $0) }
		)

		return identifiers.compactMap { identifier in
			guard let calendarEntity = calendarsByID[identifier] else {
				return nil
			}

			return calendarEntity
		}
	}

	func suggestedEntities() async throws -> [CalendarEntity] {
		await availableCalendars()
	}

	@MainActor
	private func availableCalendars() -> [CalendarEntity] {
		let eventStore = EKEventStore()
		
		return eventStore.calendars(for: .event)
			.sorted { first, second in
				let titleComparison = first.title.localizedCaseInsensitiveCompare(second.title)

				if titleComparison == .orderedSame {
					return first.source.title.localizedCaseInsensitiveCompare(second.source.title)
						== .orderedAscending
				}

				return titleComparison == .orderedAscending
			}
			.map(CalendarEntity.init(calendar:))
	}
}

struct QuoteConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Quote" }
	static var description: IntentDescription { "Choose the text shown in your quote widget." }

	@Parameter(
		title: "Enter your quote...",
		inputOptions: String.IntentInputOptions(multiline: true)
	)
	var quote: String?
}

struct EventConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Events" }
	static var description: IntentDescription {
		"Choose which calendars are shown in your event widget."
	}

	@Parameter(title: "Calendars")
	var calendars: [CalendarEntity]?

	static var parameterSummary: some ParameterSummary {
		Summary("Show \(\.$calendars)")
	}
}

struct ImageSlotConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Image" }
	static var description: IntentDescription {
		"Choose one of the images you've saved in the app."
	}

	@Parameter(title: "Image")
	var imageSlot: ImageSlotEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Display \(\.$imageSlot)")
	}
}

extension QuoteConfigurationIntent {
	var quoteText: String {
		quote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
	}
}
