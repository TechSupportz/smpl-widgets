//
//  ImageEntry.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import Foundation
import WidgetKit

struct ImageEntry: TimelineEntry {
	let date: Date
	let imageData: Data?
	let hasSavedImages: Bool
	let tintImage: Bool
	let isPlaceholder: Bool
	let isLocked: Bool

	init(
		date: Date,
		imageData: Data?,
		hasSavedImages: Bool = false,
		tintImage: Bool = false,
		isPlaceholder: Bool = false,
		isLocked: Bool = false
	) {
		self.date = date
		self.imageData = imageData
		self.hasSavedImages = hasSavedImages
		self.tintImage = tintImage
		self.isPlaceholder = isPlaceholder
		self.isLocked = isLocked
	}
}
