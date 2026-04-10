//
//  ImageWidgetPhotoService.swift
//  smpl-widgets
//
//  Created by Nitish on 03/22/26.
//

import Combine
import Photos
import PhotosUI
import SwiftUI

#if canImport(UIKit)
	import UIKit
#endif

@MainActor
final class ImageWidgetPhotoService: ObservableObject {
	enum SlotCreationError: LocalizedError {
		case missingPermission
		case unreadableImage
		case saveFailed

		var errorDescription: String? {
			switch self {
			case .missingPermission:
				return "Photos access is required to add a saved image."
			case .unreadableImage:
				return "Could not read the selected image."
			case .saveFailed:
				return "Failed to save the image for the widget."
			}
		}
	}

	@Published var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(
		for: .readWrite
	)
	@Published var isSavingSlot = false

	var isAuthorized: Bool {
		authorizationStatus == .authorized || authorizationStatus == .limited
	}

	func refreshAuthorizationStatus() {
		authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
	}

	func requestPermissionIfNeeded() async -> Bool {
		refreshAuthorizationStatus()
		if isAuthorized {
			return true
		}

		if authorizationStatus == .denied || authorizationStatus == .restricted {
			return false
		}

		let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
		authorizationStatus = status
		return status == .authorized || status == .limited
	}

	func createSlot(from item: PhotosPickerItem, quality: CGFloat = 0.85) async throws -> ImageSlotMetadata {
		guard isAuthorized else {
			throw SlotCreationError.missingPermission
		}

		isSavingSlot = true
		defer { isSavingSlot = false }

		#if canImport(UIKit)
			let selectedImage: UIImage
		#endif

		#if canImport(UIKit)
			guard
				let imageData = try await item.loadTransferable(type: Data.self),
				let image = UIImage(data: imageData)
			else {
				throw SlotCreationError.unreadableImage
			}
			selectedImage = image
		#else
			_ = item
			_ = quality
			throw SlotCreationError.unreadableImage
		#endif

		let assetMetadata = metadata(for: item)
		let displayName = makeDisplayName(
			filename: assetMetadata.filename,
			date: assetMetadata.createdAt
		)

		guard
			let savedSlot = ImageWidgetStorage.shared.addSlot(
				from: selectedImage,
				displayName: displayName,
				quality: quality
			)
		else {
			throw SlotCreationError.saveFailed
		}

		return savedSlot
	}

	private func metadata(for item: PhotosPickerItem) -> (filename: String, createdAt: Date) {
		guard let itemIdentifier = item.itemIdentifier else {
			return (filename: "Photo", createdAt: .now)
		}

		let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
		guard let asset = fetchResult.firstObject else {
			return (filename: "Photo", createdAt: .now)
		}

		let assetResources = PHAssetResource.assetResources(for: asset)
		let preferredResource = assetResources.first {
			$0.type == .photo || $0.type == .fullSizePhoto
		} ?? assetResources.first

		let rawFilename = preferredResource?.originalFilename ?? "Photo"
		let filename = cleanedFilename(from: rawFilename)
		return (filename: filename, createdAt: asset.creationDate ?? .now)
	}

	private func cleanedFilename(from originalFilename: String) -> String {
		let trimmedFilename = originalFilename.trimmingCharacters(in: .whitespacesAndNewlines)
		let baseFilename = (trimmedFilename as NSString).deletingPathExtension
		return baseFilename.isEmpty ? "Photo" : baseFilename
	}

	private func makeDisplayName(filename: String, date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return "\(filename) - \(formatter.string(from: date))"
	}
}
