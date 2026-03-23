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
	let isPlaceholder: Bool

	init(date: Date, imageData: Data?, isPlaceholder: Bool = false) {
		self.date = date
		self.imageData = imageData
		self.isPlaceholder = isPlaceholder
	}
}
