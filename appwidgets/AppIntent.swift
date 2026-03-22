//
//  AppIntent.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import AppIntents
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

struct QuoteConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Quote" }
	static var description: IntentDescription { "Choose the text shown in your quote widget." }

	@Parameter(
		title: "Enter your quote...",
		inputOptions: String.IntentInputOptions(multiline: true)
	)
	var quote: String?
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
