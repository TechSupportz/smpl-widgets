//
//  ImageTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import AppIntents
#if canImport(UIKit)
	import UIKit
#endif
import WidgetKit

struct ImageTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = ImageEntry
	typealias Intent = ImageSlotConfigurationIntent

	private let storage = ImageWidgetStorage.shared

	func placeholder(in context: Context) -> ImageEntry {
		ImageEntry(
			date: .now,
			imageData: nil,
			isPlaceholder: true
		)
	}

	func snapshot(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> ImageEntry {
		if context.isPreview {
			#if canImport(UIKit)
			return ImageEntry(
				date: .now,
				imageData: UIImage(named: "ImagePreview")?.pngData()
			)
			#else
			return ImageEntry(date: .now, imageData: nil)
			#endif
		}

		return makeEntry(for: configuration, at: .now)
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
