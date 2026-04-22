//
//  ImageWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 03/22/26.
//

import SwiftUI
import WidgetKit
import ImageIO
import UIKit

struct ImageWidgetView: View {
	@Environment(\.widgetFamily) private var family
	@Environment(\.redactionReasons) private var redactionReasons

	let entry: ImageEntry

	let insetPadding: CGFloat = 10
	let imageCornerRadius: CGFloat = 20

	private var isPlaceholder: Bool {
		redactionReasons.contains(.placeholder) || entry.isPlaceholder
	}

	private var widgetURL: URL? {
		URL(string: "smplwidgets://image")
	}

	var body: some View {
		Group {
			if isPlaceholder {
				placeholderView
			} else if let widgetImage {
				imageContent(widgetImage)
			} else {
				emptyStateView
			}
		}
		.widgetURL(widgetURL)
	}

	private var placeholderView: some View {
		imageFrameContent {
			RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
				.fill(.tertiary.opacity(0.18))
		}
	}

	private func imageContent(_ image: Image) -> some View {
		imageFrameContent {
			image
				.resizable()
				.widgetAccentedRenderingMode(entry.tintImage ? .accentedDesaturated : .fullColor)
				.scaledToFill()
		}
	}

	private func imageFrameContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
		GeometryReader { proxy in
			let imageFrameSize = CGSize(
				width: max(proxy.size.width - (insetPadding * 2), 0),
				height: max(proxy.size.height - (insetPadding * 2), 0)
			)

			content()
				.frame(
					width: imageFrameSize.width,
					height: imageFrameSize.height
				)
				.clipped()
				.clipShape(.rect(cornerRadius: imageCornerRadius))
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}

	private var emptyStateView: some View {
		VStack(spacing: 10) {
			Image(systemName: "photo.badge.plus")
				.font(.system(size: 32, weight: .medium))
				.foregroundStyle(.tertiary)

			Text("Open app to save\nan image first")
				.font(.system(size: 14, weight: .regular))
				.multilineTextAlignment(.center)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	private var widgetImage: Image? {
		guard let data = entry.imageData else {
			return nil
		}
		guard let uiImage = downsampledImage(from: data) else {
			return nil
		}
		return Image(uiImage: uiImage)
	}

	private func downsampledImage(from data: Data) -> UIImage? {
		let maxPixelSize: CGFloat
		switch family {
		case .systemSmall:
			maxPixelSize = 900
		case .systemMedium:
			maxPixelSize = 1200
		case .systemLarge:
			maxPixelSize = 1400
		default:
			maxPixelSize = 900
		}

		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
			return UIImage(data: data)
		}

		let options: CFDictionary =
			[
				kCGImageSourceCreateThumbnailFromImageAlways: true,
				kCGImageSourceCreateThumbnailWithTransform: true,
				kCGImageSourceShouldCacheImmediately: true,
				kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
			] as CFDictionary

		guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
			return UIImage(data: data)
		}

		return UIImage(cgImage: cgImage)
	}
}
