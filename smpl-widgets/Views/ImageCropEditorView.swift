//
//  ImageCropEditorView.swift
//  smpl-widgets
//
//  Created by Nitish on 04/21/26.
//

import SwiftUI
import UIKit

struct ImageCropEditorView: View {
	let slot: ImageSlotMetadata
	let originalImage: UIImage
	var onSave: () -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var squareCrop: CropRect
	@State private var wideCrop: CropRect
	@State private var selectedGroup: WidgetCropFamilyGroup = .square
	@State private var editorContainerSize: CGSize = .zero

	@State private var scale: CGFloat = 1.0
	@State private var offset: CGSize = .zero
	@State private var lastScale: CGFloat = 1.0
	@State private var lastOffset: CGSize = .zero

	init(slot: ImageSlotMetadata, image: UIImage, onSave: @escaping () -> Void) {
		self.slot = slot
		self.originalImage = image
		self.onSave = onSave

		_squareCrop = State(initialValue: slot.cropSquare ?? CropRect.defaultCrop(imageSize: image.size, maskAspect: WidgetCropFamilyGroup.square.maskAspectRatio))
		_wideCrop = State(initialValue: slot.cropWide ?? CropRect.defaultCrop(imageSize: image.size, maskAspect: WidgetCropFamilyGroup.wide.maskAspectRatio))
	}

	var body: some View {
		NavigationStack {
			scrollContent
				.navigationTitle(slot.displayName)
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						Button("Close") {
							dismiss()
						}
						.foregroundStyle(.secondary)
					}
					ToolbarItem(placement: .topBarTrailing) {
						Button("Save") {
							saveAndDismiss()
						}
						.fontWeight(.semibold)
					}
				}
		}
	}

	// MARK: - Scrollable Content

	private var scrollContent: some View {
		GeometryReader { geometry in
			ScrollView(.vertical) {
				VStack(spacing: 20) {
					tabPicker
					cropEditor(containerWidth: geometry.size.width - ImageCropEditorLayout.horizontalPadding * 2)
					controls
				}
				.padding(.bottom, 32)
			}
		}
	}

	// MARK: - Tab Picker

	private var tabPicker: some View {
		Picker("Crop Mode", selection: $selectedGroup) {
			Text("Small & Large").tag(WidgetCropFamilyGroup.square)
			Text("Medium").tag(WidgetCropFamilyGroup.wide)
		}
		.pickerStyle(.segmented)
		.padding(.horizontal)
		.padding(.top, 8)
	}

	// MARK: - Crop Editor Canvas

	private func cropEditor(containerWidth: CGFloat) -> some View {
		GeometryReader { geo in
			let containerSize = geo.size
			let maskAspect = selectedGroup.maskAspectRatio
			let maskSize = cropMaskSize(containerSize: containerSize, maskAspect: maskAspect)
			let renderedSize = renderedImageSize(
				containerSize: containerSize,
				imageSize: originalImage.size,
				scale: scale
			)

			ZStack {
				Image(uiImage: originalImage)
					.resizable()
					.frame(width: renderedSize.width, height: renderedSize.height)
					.position(
						x: (containerSize.width / 2) + offset.width,
						y: (containerSize.height / 2) + offset.height
					)

				Canvas { context, size in
					context.fill(
						Path(CGRect(origin: .zero, size: size)),
						with: .color(.black.opacity(0.5))
					)
					let holeRect = CGRect(
						x: (size.width - maskSize.width) / 2,
						y: (size.height - maskSize.height) / 2,
						width: maskSize.width,
						height: maskSize.height
					)
					context.blendMode = .clear
					context.fill(
						Path(roundedRect: holeRect, cornerRadius: 20),
						with: .color(.clear)
					)
				}

				RoundedRectangle(cornerRadius: 20)
					.stroke(.white, lineWidth: 2)
					.frame(width: maskSize.width, height: maskSize.height)
			}
			.clipped()
			.contentShape(Rectangle())
			.gesture(
				SimultaneousGesture(
					MagnifyGesture()
						.onChanged { value in
							scale = lastScale * value.magnification
							applyClamping(containerSize: containerSize, maskAspect: maskAspect)
						}
						.onEnded { _ in
							lastScale = scale
						},
					DragGesture()
						.onChanged { value in
							offset = CGSize(
								width: lastOffset.width + value.translation.width,
								height: lastOffset.height + value.translation.height
							)
							applyClamping(containerSize: containerSize, maskAspect: maskAspect)
						}
						.onEnded { _ in
							lastOffset = offset
						}
					)
				)
				.onAppear {
					syncEditorState(to: containerSize, for: selectedGroup)
				}
				.onChange(of: containerSize) { _, newSize in
					syncEditorState(to: newSize, for: selectedGroup)
				}
				.onChange(of: selectedGroup) { oldGroup, newGroup in
					guard editorContainerSize != .zero else { return }
					saveCurrentCrop(
						for: oldGroup,
						containerSize: editorContainerSize,
						maskAspect: oldGroup.maskAspectRatio
					)
					setupState(
						for: newGroup,
						containerSize: editorContainerSize,
						maskAspect: newGroup.maskAspectRatio
					)
				}
			}
		.frame(maxWidth: .infinity)
		.frame(
			height: cropEditorHeight(
				containerWidth: containerWidth,
				maskAspect: selectedGroup.maskAspectRatio
			)
		)
		.padding(.horizontal)
		.clipShape(.rect(cornerRadius: 16))
	}

	// MARK: - Controls

	private var controls: some View {
		HStack(spacing: 16) {
			Button {
				resetCurrentCrop()
			} label: {
				Label("Reset", systemImage: "arrow.uturn.backward")
			}
			.buttonStyle(.bordered)

			Spacer()
		}
		.padding(.horizontal)
	}

	// MARK: - Actions

	private func saveAndDismiss() {
		guard editorContainerSize != .zero else {
			dismiss()
			return
		}
		saveCurrentCrop(
			for: selectedGroup,
			containerSize: editorContainerSize,
			maskAspect: selectedGroup.maskAspectRatio
		)
		ImageWidgetStorage.shared.updateCrop(
			forSlotID: slot.id,
			square: squareCrop,
			wide: wideCrop
		)
		onSave()
		dismiss()
	}

	private func resetCurrentCrop() {
		let defaultCrop = CropRect.defaultCrop(
			imageSize: originalImage.size,
			maskAspect: selectedGroup.maskAspectRatio
		)
		switch selectedGroup {
		case .square:
			squareCrop = defaultCrop
		case .wide:
			wideCrop = defaultCrop
		}
		if editorContainerSize != .zero {
			setupState(
				for: selectedGroup,
				containerSize: editorContainerSize,
				maskAspect: selectedGroup.maskAspectRatio
			)
		}
	}

	private func saveCurrentCrop(
		for group: WidgetCropFamilyGroup,
		containerSize: CGSize,
		maskAspect: CGFloat
	) {
		let crop = computeCropRect(
			containerSize: containerSize,
			imageSize: originalImage.size,
			maskAspect: maskAspect
		)
		switch group {
		case .square:
			squareCrop = crop
		case .wide:
			wideCrop = crop
		}
	}

	private func setupState(for group: WidgetCropFamilyGroup, containerSize: CGSize, maskAspect: CGFloat) {
		let crop = group == .square ? squareCrop : wideCrop
		let (newScale, newOffset) = computeScaleOffset(
			crop: crop,
			containerSize: containerSize,
			imageSize: originalImage.size,
			maskAspect: maskAspect
		)
		scale = newScale
		lastScale = newScale
		offset = newOffset
		lastOffset = newOffset
	}

	private func syncEditorState(to containerSize: CGSize, for group: WidgetCropFamilyGroup) {
		guard containerSize != .zero else { return }

		let previousSize = editorContainerSize
		if previousSize == .zero {
			editorContainerSize = containerSize
			setupState(for: group, containerSize: containerSize, maskAspect: group.maskAspectRatio)
			return
		}

		guard previousSize != containerSize else { return }

		saveCurrentCrop(for: group, containerSize: previousSize, maskAspect: group.maskAspectRatio)
		editorContainerSize = containerSize
		setupState(for: group, containerSize: containerSize, maskAspect: group.maskAspectRatio)
	}

	// MARK: - Geometry

	private func renderedImageSize(containerSize: CGSize, imageSize: CGSize, scale: CGFloat) -> CGSize {
		let baseScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
		return CGSize(
			width: imageSize.width * baseScale * scale,
			height: imageSize.height * baseScale * scale
		)
	}

	private func computeScaleOffset(
		crop: CropRect,
		containerSize: CGSize,
		imageSize: CGSize,
		maskAspect: CGFloat
	) -> (scale: CGFloat, offset: CGSize) {
		let maskSize = cropMaskSize(containerSize: containerSize, maskAspect: maskAspect)
		let maskW = maskSize.width
		let baseScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
		let scaleVal = maskW / (crop.width * imageSize.width * baseScale)
		let renderedW = imageSize.width * baseScale * scaleVal
		let renderedH = imageSize.height * baseScale * scaleVal

		let maskLeft = (containerSize.width - maskW) / 2
		let maskTop = (containerSize.height - maskSize.height) / 2

		let offsetX = maskLeft - containerSize.width / 2 - (crop.x - 0.5) * renderedW
		let offsetY = maskTop - containerSize.height / 2 - (crop.y - 0.5) * renderedH

		return (scaleVal, CGSize(width: offsetX, height: offsetY))
	}

	private func computeCropRect(
		containerSize: CGSize,
		imageSize: CGSize,
		maskAspect: CGFloat
	) -> CropRect {
		let maskSize = cropMaskSize(containerSize: containerSize, maskAspect: maskAspect)
		let maskW = maskSize.width
		let maskH = maskSize.height
		let baseScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
		let renderedW = imageSize.width * baseScale * scale
		let renderedH = imageSize.height * baseScale * scale

		let maskLeft = (containerSize.width - maskW) / 2
		let maskTop = (containerSize.height - maskH) / 2

		let normX = (maskLeft - containerSize.width / 2 - offset.width) / renderedW + 0.5
		let normY = (maskTop - containerSize.height / 2 - offset.height) / renderedH + 0.5
		let normW = maskW / renderedW
		let normH = maskH / renderedH

		return CropRect(
			x: max(0, min(1 - normW, normX)),
			y: max(0, min(1 - normH, normY)),
			width: min(1, normW),
			height: min(1, normH)
		)
	}

	private func applyClamping(containerSize: CGSize, maskAspect: CGFloat) {
		let maskSize = cropMaskSize(containerSize: containerSize, maskAspect: maskAspect)
		let maskW = maskSize.width
		let maskH = maskSize.height
		let baseScale = max(containerSize.width / originalImage.size.width, containerSize.height / originalImage.size.height)
		let minScaleW = maskW / (originalImage.size.width * baseScale)
		let minScaleH = maskH / (originalImage.size.height * baseScale)
		let minScale = max(minScaleW, minScaleH)
		scale = max(minScale, min(scale, 8.0))

		let renderedW = originalImage.size.width * baseScale * scale
		let renderedH = originalImage.size.height * baseScale * scale

		let maskLeft = (containerSize.width - maskW) / 2
		let maskTop = (containerSize.height - maskH) / 2

		var normX = (maskLeft - containerSize.width / 2 - offset.width) / renderedW + 0.5
		var normY = (maskTop - containerSize.height / 2 - offset.height) / renderedH + 0.5
		let normW = maskW / renderedW
		let normH = maskH / renderedH

		normX = max(0, min(1 - normW, normX))
		normY = max(0, min(1 - normH, normY))

		offset = CGSize(
			width: maskLeft - containerSize.width / 2 - (normX - 0.5) * renderedW,
			height: maskTop - containerSize.height / 2 - (normY - 0.5) * renderedH
		)
	}

	private func cropEditorHeight(containerWidth: CGFloat, maskAspect: CGFloat) -> CGFloat {
		let safeWidth = max(0, containerWidth)
		let targetMaskWidth = safeWidth * ImageCropEditorLayout.maskWidthRatio
		let targetHeight = targetMaskWidth / maskAspect + ImageCropEditorLayout.verticalMaskPadding

		return min(
			ImageCropEditorLayout.maximumHeight,
			max(ImageCropEditorLayout.minimumHeight, targetHeight)
		)
	}

	private func cropMaskSize(containerSize: CGSize, maskAspect: CGFloat) -> CGSize {
		guard containerSize.width > 0, containerSize.height > 0, maskAspect > 0 else {
			return .zero
		}

		let widthLimit = containerSize.width * ImageCropEditorLayout.maskWidthRatio
		let heightLimit = containerSize.height * ImageCropEditorLayout.maskHeightRatio
		let width = min(widthLimit, heightLimit * maskAspect)

		return CGSize(width: width, height: width / maskAspect)
	}
}

private enum ImageCropEditorLayout {
	static let horizontalPadding: CGFloat = 16
	static let maskWidthRatio: CGFloat = 0.8
	static let maskHeightRatio: CGFloat = 0.86
	static let verticalMaskPadding: CGFloat = 48
	static let minimumHeight: CGFloat = 300
	static let maximumHeight: CGFloat = 560
}

// MARK: - Preview Helpers

private func previewImage() -> UIImage {
	let size = CGSize(width: 800, height: 600)
	let format = UIGraphicsImageRendererFormat()
	format.scale = 1
	return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
		let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
		let gradient = CGGradient(
			colorsSpace: CGColorSpaceCreateDeviceRGB(),
			colors: colors as CFArray,
			locations: [0.0, 1.0]
		)!
		ctx.cgContext.drawLinearGradient(
			gradient,
			start: CGPoint(x: 0, y: 0),
			end: CGPoint(x: size.width, y: size.height),
			options: []
		)
		for i in 0..<6 {
			let rect = CGRect(
				x: CGFloat(i) * 100 + 50,
				y: CGFloat(i) * 80 + 50,
				width: 120,
				height: 120
			)
			UIColor.white.withAlphaComponent(0.3).setFill()
			ctx.cgContext.fillEllipse(in: rect)
		}
	}
}

// MARK: - Canvas Preview

#Preview("Image Crop Editor") {
	let image = previewImage()
	let slot = ImageSlotMetadata(
		id: "preview",
		displayName: "Beach Trip",
		fileName: "IMG_preview.jpg",
		createdAt: .now,
		cropSquare: nil,
		cropWide: nil
	)

	return ImageCropEditorView(
		slot: slot,
		image: image,
		onSave: {}
	)
}
