//
//  ImageTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import AppIntents
import UIKit
import WidgetKit

struct ImageTimelineProvider: AppIntentTimelineProvider {
	typealias Entry = ImageEntry
	typealias Intent = ImageSlotConfigurationIntent

	private let storage = ImageWidgetStorage.shared
	private let premiumPreviewImageData = UIImage(named: "ImagePreview")?.pngData()

	func placeholder(in context: Context) -> ImageEntry {
		premiumPreviewEntry(
			tintImage: false,
			isPlaceholder: true,
			isLocked: !PremiumConfiguration.isUnlocked
		)
	}

	func snapshot(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> ImageEntry {
		if !PremiumConfiguration.isUnlocked {
			return premiumPreviewEntry(tintImage: configuration.tintImageEnabled)
		}

		if context.isPreview {
			return ImageEntry(
				date: .now,
				imageData: premiumPreviewImageData,
				tintImage: configuration.tintImageEnabled
			)
		}

		return makeEntry(for: configuration, at: .now, family: context.family)
	}

	func timeline(for configuration: ImageSlotConfigurationIntent, in context: Context) async -> Timeline<ImageEntry> {
		if !PremiumConfiguration.isUnlocked {
			let entry = premiumPreviewEntry(tintImage: configuration.tintImageEnabled)
			return Timeline(entries: [entry], policy: .never)
		}

		let entry = makeEntry(for: configuration, at: .now, family: context.family)
		return Timeline(entries: [entry], policy: .never)
	}

	private func makeEntry(for configuration: ImageSlotConfigurationIntent, at date: Date, family: WidgetFamily?) -> ImageEntry {
		let hasSavedImages = !storage.allSlots.isEmpty
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
				imageData: imageData,
				hasSavedImages: hasSavedImages,
				tintImage: configuration.tintImageEnabled
			)
		}

	private func premiumPreviewEntry(
		tintImage: Bool,
		isPlaceholder: Bool = false,
		isLocked: Bool = true
	) -> ImageEntry {
		ImageEntry(
			date: .now,
			imageData: premiumPreviewImageData,
			hasSavedImages: true,
			tintImage: tintImage,
			isPlaceholder: isPlaceholder,
			isLocked: isLocked
		)
	}
}
