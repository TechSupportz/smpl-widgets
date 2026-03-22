//
//  ImageWidget.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct ImageWidget: Widget {
	let kind: String = "ImageWidget"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: ImageSlotConfigurationIntent.self,
			provider: ImageTimelineProvider()
		) { entry in
			ImageWidgetView(entry: entry)
				.alwaysWhiteWidgetStyle()
		}
		.contentMarginsDisabled()
		.configurationDisplayName("smpl.image")
		.description("Show one of the images you've saved in the app.")
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

#Preview("No Image", as: .systemSmall) {
	ImageWidget()
} timeline: {
	ImageEntry(
		date: .now,
		imageData: nil
	)
}

#Preview("With Image", as: .systemSmall) {
	ImageWidget()
} timeline: {
	#if canImport(UIKit)
		let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600))
		let previewImage = renderer.image { context in
			UIColor.systemYellow.setFill()
			context.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
			UIColor.black.setFill()
			let text = "smpl."
			let textAttributes: [NSAttributedString.Key: Any] = [
				.font: UIFont.systemFont(ofSize: 120, weight: .bold),
				.foregroundColor: UIColor.black,
			]
			text.draw(at: CGPoint(x: 120, y: 240), withAttributes: textAttributes)
		}
	#else
		let previewImage = UIImage()
	#endif

	ImageEntry(
		date: .now,
		imageData: previewImage.pngData()
	)
}
