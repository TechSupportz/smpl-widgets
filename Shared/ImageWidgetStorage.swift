//
//  ImageWidgetStorage.swift
//  smpl-widgets
//
//  Created by Nitish on 03/22/26.
//

import Foundation
import ImageIO

#if canImport(UIKit)
	import UIKit
	import UniformTypeIdentifiers
#endif

private struct LegacyImageWidgetAlbumCache: Codable {
	let fileNames: [String]
}

final class ImageWidgetStorage {
	static let shared = ImageWidgetStorage()

	private let appGroupID = "group.com.tnitish.smpl-widgets"
	private let rootDirectoryName = "ImageWidgetCache"
	private let slotsKey = "com.tnitish.smpl-widgets.imageWidget.slots"
	private let legacySingleImageFileNameKey = "com.tnitish.smpl-widgets.imageWidget.singleImageFileName"
	private let legacyAlbumCacheKey = "com.tnitish.smpl-widgets.imageWidget.albumCache"
	private let maxExportDimension: CGFloat = 1400
	private let maxExportArea: CGFloat = 1_000_000

	private let fileManager = FileManager.default
	private let userDefaults: UserDefaults

	private init() {
		self.userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
		cleanupLegacyStorageIfNeeded()
	}

	var allSlots: [ImageSlotMetadata] {
		let storedSlots = readStoredSlots()
		let validSlots = storedSlots.filter { fileURL(for: $0.fileName) != nil }

		if validSlots.count != storedSlots.count {
			_ = writeStoredSlots(validSlots)
		}

		return validSlots.sorted { left, right in
			if left.createdAt == right.createdAt {
				return left.displayName.localizedStandardCompare(right.displayName)
					== .orderedAscending
			}

			return left.createdAt > right.createdAt
		}
	}

	func slot(for id: String) -> ImageSlotMetadata? {
		allSlots.first { $0.id == id }
	}

	func imageData(forSlotID id: String) -> Data? {
		guard let slot = slot(for: id) else {
			return nil
		}

		return readData(for: slot.fileName)
	}

	#if canImport(UIKit)

	func imageData(forSlotID id: String, cropFamilyGroup: WidgetCropFamilyGroup) -> Data? {
		guard let slot = slot(for: id),
			let originalData = readData(for: slot.fileName),
			let originalImage = UIImage(data: originalData),
			let cgImage = originalImage.cgImage
		else {
			return imageData(forSlotID: id)
		}

		let cropRect: CropRect
		switch cropFamilyGroup {
		case .square:
			if let explicitCrop = slot.cropSquare {
				cropRect = explicitCrop
			} else {
				cropRect = CropRect.defaultCrop(
					imageSize: originalImage.size,
					maskAspect: cropFamilyGroup.maskAspectRatio
				)
			}
		case .wide:
			if let explicitCrop = slot.cropWide {
				cropRect = explicitCrop
			} else {
				cropRect = CropRect.defaultCrop(
					imageSize: originalImage.size,
					maskAspect: cropFamilyGroup.maskAspectRatio
				)
			}
		}

		let pixelCrop = CGRect(
			x: cropRect.x * originalImage.size.width,
			y: cropRect.y * originalImage.size.height,
			width: cropRect.width * originalImage.size.width,
			height: cropRect.height * originalImage.size.height
		)

		guard let croppedCGImage = cgImage.cropping(to: pixelCrop) else {
			return imageData(forSlotID: id)
		}

		let croppedImage = UIImage(cgImage: croppedCGImage)
		return croppedImage.jpegData(compressionQuality: 0.92)
	}

	#endif

	func updateCrop(forSlotID id: String, square: CropRect?, wide: CropRect?) {
		var slots = readStoredSlots()
		guard let index = slots.firstIndex(where: { $0.id == id }) else { return }

		slots[index].cropSquare = square
		slots[index].cropWide = wide
		_ = writeStoredSlots(slots)
	}

	#if canImport(UIKit)

	@discardableResult
	func addSlot(
		from image: UIImage,
		displayName: String,
		quality: CGFloat = 0.85
	) -> ImageSlotMetadata? {
		guard let encodedImage = encodedImageData(from: image, quality: quality),
			let rootDirectoryURL
		else {
			return nil
		}

		let slotID = UUID().uuidString
		let fileName = "slot-\(slotID).\(encodedImage.fileExtension)"
		let fileURL = rootDirectoryURL.appendingPathComponent(fileName)

		do {
			try encodedImage.data.write(to: fileURL, options: .atomic)
		} catch {
			return nil
		}

		let slot = ImageSlotMetadata(
			id: slotID,
			displayName: displayName,
			fileName: fileName,
			createdAt: .now
		)

		var slots = readStoredSlots()
		slots.append(slot)

		guard writeStoredSlots(slots) else {
			removeFileIfNeeded(named: fileName)
			return nil
		}

		return slot
	}

	#endif

	func deleteSlot(id: String) {
		var slots = readStoredSlots()
		guard let index = slots.firstIndex(where: { $0.id == id }) else {
			return
		}

		let slot = slots.remove(at: index)
		guard writeStoredSlots(slots) else {
			return
		}

		removeFileIfNeeded(named: slot.fileName)
	}

	private func readStoredSlots() -> [ImageSlotMetadata] {
		guard let data = userDefaults.data(forKey: slotsKey) else {
			return []
		}

		return (try? JSONDecoder().decode([ImageSlotMetadata].self, from: data)) ?? []
	}

	@discardableResult
	private func writeStoredSlots(_ slots: [ImageSlotMetadata]) -> Bool {
		if slots.isEmpty {
			userDefaults.removeObject(forKey: slotsKey)
			userDefaults.synchronize()
			return true
		}

		guard let data = try? JSONEncoder().encode(slots) else {
			return false
		}

		userDefaults.set(data, forKey: slotsKey)
		userDefaults.synchronize()
		return true
	}

	private func cleanupLegacyStorageIfNeeded() {
		if let fileName = userDefaults.string(forKey: legacySingleImageFileNameKey) {
			removeFileIfNeeded(named: fileName)
			userDefaults.removeObject(forKey: legacySingleImageFileNameKey)
		}

		if let data = userDefaults.data(forKey: legacyAlbumCacheKey) {
			if let cache = try? JSONDecoder().decode(LegacyImageWidgetAlbumCache.self, from: data) {
				for fileName in cache.fileNames {
					removeFileIfNeeded(named: fileName)
				}
			}

			userDefaults.removeObject(forKey: legacyAlbumCacheKey)
		}

		userDefaults.synchronize()
	}

	private func readData(for fileName: String) -> Data? {
		guard let fileURL = fileURL(for: fileName) else {
			return nil
		}

		return try? Data(contentsOf: fileURL)
	}

	#if canImport(UIKit)

	private func encodedImageData(from image: UIImage, quality: CGFloat) -> (data: Data, fileExtension: String)? {
		guard let renderedImage = renderedImage(from: image, maxDimension: maxExportDimension),
			let cgImage = renderedImage.cgImage
		else {
			return nil
		}

		let clampedQuality = min(max(quality, 0), 1)
		let compressionOptions = [
			kCGImageDestinationLossyCompressionQuality: clampedQuality,
		] as CFDictionary

		let heicData = NSMutableData()
		if let destination = CGImageDestinationCreateWithData(
			heicData,
			UTType.heic.identifier as CFString,
			1,
			nil
		) {
			CGImageDestinationAddImage(destination, cgImage, compressionOptions)
			if CGImageDestinationFinalize(destination) {
				return (heicData as Data, "heic")
			}
		}

		guard let jpegData = renderedImage.jpegData(compressionQuality: clampedQuality) else {
			return nil
		}

		return (jpegData, "jpg")
	}

	private func renderedImage(from image: UIImage, maxDimension: CGFloat) -> UIImage? {
		guard image.size.width > 0, image.size.height > 0 else {
			return nil
		}

		let size = image.size
		let area = size.width * size.height
		let dimensionScale = maxDimension / max(size.width, size.height)
		let areaScale = sqrt(maxExportArea / area)
		let scaleRatio = min(1, dimensionScale, areaScale)

		let targetSize = CGSize(
			width: size.width * scaleRatio,
			height: size.height * scaleRatio
		)

		let format = UIGraphicsImageRendererFormat.default()
		format.scale = 1
		format.opaque = true

		let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
		return renderer.image { _ in
			UIColor.white.setFill()
			UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
			image.draw(in: CGRect(origin: .zero, size: targetSize))
		}
	}

	#endif

	private var rootDirectoryURL: URL? {
		guard let containerURL = fileManager.containerURL(
			forSecurityApplicationGroupIdentifier: appGroupID
		) else {
			return nil
		}

		let directoryURL = containerURL.appendingPathComponent(
			rootDirectoryName,
			isDirectory: true
		)

		if !fileManager.fileExists(atPath: directoryURL.path) {
			do {
				try fileManager.createDirectory(
					at: directoryURL,
					withIntermediateDirectories: true
				)
			} catch {
				return nil
			}
		}

		return directoryURL
	}

	private func fileURL(for fileName: String) -> URL? {
		guard let rootDirectoryURL else {
			return nil
		}

		let fileURL = rootDirectoryURL.appendingPathComponent(fileName)
		guard fileManager.fileExists(atPath: fileURL.path) else {
			return nil
		}

		return fileURL
	}

	private func removeFileIfNeeded(named fileName: String) {
		guard let fileURL = fileURL(for: fileName) else {
			return
		}

		try? fileManager.removeItem(at: fileURL)
	}
}
