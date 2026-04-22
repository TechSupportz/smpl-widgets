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
	let tintImage: Bool
	let isPlaceholder: Bool

	init(date: Date, imageData: Data?, tintImage: Bool = false, isPlaceholder: Bool = false) {
		self.date = date
		self.imageData = imageData
		self.tintImage = tintImage
		self.isPlaceholder = isPlaceholder
	}
}
