//
//  ImageWidgetTypes.swift
//  smpl-widgets
//
//  Created by Nitish on 03/22/26.
//

import Foundation

struct CropRect: Codable, Hashable {
	let x: CGFloat
	let y: CGFloat
	let width: CGFloat
	let height: CGFloat

	static func defaultCrop(imageSize: CGSize, maskAspect: CGFloat) -> CropRect {
		let imageAspect = imageSize.width / imageSize.height

		if imageAspect > maskAspect {
			let normH = 1.0
			let normW = maskAspect / imageAspect
			return CropRect(x: (1.0 - normW) / 2.0, y: 0, width: normW, height: normH)
		} else {
			let normW = 1.0
			let normH = imageAspect / maskAspect
			return CropRect(x: 0, y: (1.0 - normH) / 2.0, width: normW, height: normH)
		}
	}
}

enum WidgetCropFamilyGroup: String, Codable, Hashable {
	case square
	case wide

	var maskAspectRatio: CGFloat {
		switch self {
		case .square: return 1.0
		case .wide: return 2.13
		}
	}
}

struct ImageSlotMetadata: Codable, Identifiable, Hashable {
	let id: String
	let displayName: String
	let fileName: String
	let createdAt: Date
	var cropSquare: CropRect?
	var cropWide: CropRect?
}
