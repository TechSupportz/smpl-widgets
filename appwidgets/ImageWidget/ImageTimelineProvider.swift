//
//  ImageTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import AppIntents
import WidgetKit

struct ImageTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = ImageEntry
	typealias Intent = ImageSlotConfigurationIntent

	private let storage = ImageWidgetStorage.shared

	func placeholder(in context: Context) -> ImageEntry {
		ImageEntry(
			date: .now,
			imageData: nil
		)
	}

	func snapshot(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> ImageEntry {
		makeEntry(for: configuration, at: .now)
	}

	func timeline(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> Timeline<ImageEntry> {
		let entry = makeEntry(for: configuration, at: .now)
		return Timeline(entries: [entry], policy: .never)
	}

	private func makeEntry(for configuration: ImageSlotConfigurationIntent, at date: Date) -> ImageEntry {
		let imageData = configuration.imageSlot.flatMap { slot in
			storage.imageData(forSlotID: slot.id)
		}

		return ImageEntry(
			date: date,
			imageData: imageData
		)
	}
}
