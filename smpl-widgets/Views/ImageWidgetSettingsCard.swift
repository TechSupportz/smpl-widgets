//
//  ImageWidgetSettingsCard.swift
//  smpl-widgets
//
//  Created by Nitish on 22/03/26.
//

import PhotosUI
import SwiftUI
import UIKit
import WidgetKit

struct ImageWidgetSettingsCard: View {
	let isSaving: Bool
	let slots: [ImageSlotMetadata]

	var selectedImageSlotItem: Binding<PhotosPickerItem?>
	var onDeleteSlot: (ImageSlotMetadata) -> Void
	var onCropSaved: () -> Void

	@State private var editingSlotID: String? = nil

	private let slotListMaxHeight: CGFloat = 280

	private var displayedSlots: [ImageSlotMetadata] {
		slots
	}

	private var activeEditingSlot: ImageSlotMetadata? {
		guard let editingSlotID else {
			return nil
		}

		return ImageWidgetStorage.shared.slot(for: editingSlotID)
			?? slots.first(where: { $0.id == editingSlotID })
	}

	var body: some View {
		VStack(spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: "photo.fill.on.rectangle.fill")
					.font(.title2)
					.foregroundStyle(.blue)

				VStack(alignment: .leading, spacing: 4) {
					Text("Image Widget")
						.font(.headline)
					Text("Choose photos without granting full library access")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			Text(
				"Add photos here, then long-press the widget on your home screen to choose what's displayed."
			)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)

			if slots.isEmpty {
				Text("No saved images yet")
					.font(.callout)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
			} else {
				ScrollView(.vertical) {
					VStack(spacing: 12) {
						ForEach(displayedSlots) { slot in
							slotRow(slot)
						}
					}
				}
				.frame(maxHeight: slotListMaxHeight)
				.scrollIndicators(.hidden)
				.contentMargins(.top, 8)
				.contentMargins(.bottom, 8)
				.mask {
					VStack(spacing: 0) {
						LinearGradient(
							colors: [.clear, .black], startPoint: .top, endPoint: .bottom
						)
						.frame(height: 8)
						Color.black
						LinearGradient(
							colors: [.black, .clear], startPoint: .top, endPoint: .bottom
						)
						.frame(height: 8)
					}
				}
			}

			PhotosPicker(
				selection: selectedImageSlotItem,
				matching: .images
			) {
				Label(
					isSaving ? "Saving..." : "Add Image",
					systemImage: "photo.badge.plus.fill"
				)
				.padding(.vertical, 8)
			}
			.disabled(isSaving)
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
		.sheet(
			isPresented: Binding(
				get: { activeEditingSlot != nil },
				set: { isPresented in
					if !isPresented {
						editingSlotID = nil
					}
				}
			)
		) {
			if let slot = activeEditingSlot,
				let data = ImageWidgetStorage.shared.imageData(forSlotID: slot.id),
				let image = UIImage(data: data)
			{
				ImageCropEditorView(
					slot: slot,
					image: image,
					onSave: {
						onCropSaved()
						WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
					}
				)
			}
		}
	}

	private func slotRow(_ slot: ImageSlotMetadata) -> some View {
		HStack(spacing: 16) {
			slotThumbnail(slot)

			Text(slot.displayName)
				.font(.body)
				.frame(maxWidth: .infinity, alignment: .leading)

			Button {
				editingSlotID = slot.id
			} label: {
				Image(systemName: "crop")
					.font(.body)
			}
			.buttonStyle(.borderless)

			Button(role: .destructive) {
				onDeleteSlot(slot)
			} label: {
				Image(systemName: "trash")
					.font(.body)
			}
			.buttonStyle(.borderless)
		}
		.padding(.vertical, 12)
		.padding(.horizontal, 12)
		.background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
	}

	@ViewBuilder
	private func slotThumbnail(_ slot: ImageSlotMetadata) -> some View {
		if let imageData = ImageWidgetStorage.shared.imageData(forSlotID: slot.id),
			let image = UIImage(data: imageData)
		{
			Image(uiImage: image)
				.resizable()
				.scaledToFill()
				.frame(width: 40, height: 40)
				.clipShape(.rect(cornerRadius: 8))
		} else {
			thumbnailPlaceholder
		}
	}

	private var thumbnailPlaceholder: some View {
		Image(systemName: "photo")
			.font(.footnote)
			.foregroundStyle(.secondary)
			.frame(width: 40, height: 40)
			.background(.white.opacity(0.08), in: .rect(cornerRadius: 8))
	}
}

// MARK: - Previews

private let mockSlots: [ImageSlotMetadata] = [
	ImageSlotMetadata(
		id: "1",
		displayName: "Beach Trip - Jan 1, 2025",
		fileName: "IMG_001.jpg",
		createdAt: .now
	),
	ImageSlotMetadata(
		id: "2",
		displayName: "Sunset - Mar 5, 2025",
		fileName: "IMG_002.jpg",
		createdAt: .now
	),
]

#Preview("Empty") {
	ImageWidgetSettingsCard(
		isSaving: false,
		slots: [],
		selectedImageSlotItem: .constant(nil),
		onDeleteSlot: { _ in },
		onCropSaved: {}
	)
	.padding()
}

#Preview("With slots") {
	ImageWidgetSettingsCard(
		isSaving: false,
		slots: mockSlots,
		selectedImageSlotItem: .constant(nil),
		onDeleteSlot: { _ in },
		onCropSaved: {}
	)
	.padding()
}

#Preview("Saving in progress") {
	ImageWidgetSettingsCard(
		isSaving: true,
		slots: mockSlots,
		selectedImageSlotItem: .constant(nil),
		onDeleteSlot: { _ in },
		onCropSaved: {}
	)
	.padding()
}
