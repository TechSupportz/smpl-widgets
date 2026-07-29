//
//  ImageWidgetPhotoService.swift
//  smpl-widgets
//
//  Created by Nitish on 03/22/26.
//

import Combine
import ImageIO
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ImageWidgetPhotoService: ObservableObject {
	enum SlotCreationError: LocalizedError {
		case unreadableImage
		case saveFailed

		var errorDescription: String? {
			switch self {
			case .unreadableImage:
				return "Could not read the selected image."
			case .saveFailed:
				return "Failed to save the image for the widget."
			}
		}
	}

	@Published var isSavingSlot = false
	private let maxImportPixelSize = 1_600

	func createSlot(
		from item: PhotosPickerItem, quality: CGFloat = 0.85
	) async throws -> ImageSlotMetadata {
		isSavingSlot = true
		defer { isSavingSlot = false }

		guard
			let imageData = try await item.loadTransferable(type: Data.self),
			let image = downsampledImage(from: imageData)
		else {
			throw SlotCreationError.unreadableImage
		}

		let displayName = makeDisplayName(date: .now)

		guard
			let savedSlot = ImageWidgetStorage.shared.addSlot(
				from: image,
				displayName: displayName,
				quality: quality
			)
		else {
			throw SlotCreationError.saveFailed
		}

		return savedSlot
	}

	private func downsampledImage(from data: Data) -> UIImage? {
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
			return nil
		}

		let options =
			[
				kCGImageSourceCreateThumbnailFromImageAlways: true,
				kCGImageSourceCreateThumbnailWithTransform: true,
				kCGImageSourceShouldCacheImmediately: true,
				kCGImageSourceThumbnailMaxPixelSize: maxImportPixelSize,
			] as CFDictionary

		guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
			return nil
		}

		return UIImage(cgImage: cgImage)
	}

	private func makeDisplayName(date: Date) -> String {
		"Photo - \(date.formatted(date: .abbreviated, time: .shortened))"
	}
}
