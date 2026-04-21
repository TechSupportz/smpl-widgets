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

		return makeEntry(for: configuration, at: .now, family: context.family)
	}

	func timeline(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> Timeline<ImageEntry> {
		let entry = makeEntry(for: configuration, at: .now, family: context.family)
		return Timeline(entries: [entry], policy: .never)
	}

	private func makeEntry(for configuration: ImageSlotConfigurationIntent, at date: Date, family: WidgetFamily?) -> ImageEntry {
		let imageData = configuration.imageSlot.flatMap { slot -> Data? in
			guard let family else {
				return storage.imageData(forSlotID: slot.id)
			}
			let group: WidgetCropFamilyGroup
			switch family {
			case .systemSmall, .systemLarge:
				group = .square
			case .systemMedium:
				group = .wide
			default:
				group = .square
			}
			return storage.imageData(forSlotID: slot.id, cropFamilyGroup: group)
		}

		return ImageEntry(
			date: date,
			imageData: imageData
		)
	}
}
