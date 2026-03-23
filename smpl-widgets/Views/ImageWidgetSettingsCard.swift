//
//  ImageWidgetSettingsCard.swift
//  smpl-widgets
//
//  Created by Nitish on 22/03/26.
//

import PhotosUI
import SwiftUI

#if canImport(UIKit)
	import UIKit
#endif

struct ImageWidgetSettingsCard: View {
	let isAuthorized: Bool
	let isSaving: Bool
	let slots: [ImageSlotMetadata]
	let permissionButtonTitle: String

	var selectedImageSlotItem: Binding<PhotosPickerItem?>
	var onPermissionTap: () -> Void
	var onDeleteSlot: (ImageSlotMetadata) -> Void

	private var statusIcon: String {
		isAuthorized ? "photo.fill.on.rectangle.fill" : "photo"
	}

	private var statusColor: Color {
		isAuthorized ? .blue : .orange
	}

	private var statusText: String {
		isAuthorized ? "Enabled for saved image slots" : "Not configured"
	}

	private let slotListMaxHeight: CGFloat = 280

	private var displayedSlots: [ImageSlotMetadata] {
		Array(slots.reversed())
	}

	var body: some View {
		VStack(spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: statusIcon)
					.font(.title2)
					.foregroundStyle(statusColor)

				VStack(alignment: .leading, spacing: 4) {
					Text("Image Widget")
						.font(.headline)
					Text(statusText)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			if !isAuthorized {
				Button(permissionButtonTitle) {
					onPermissionTap()
				}
				.buttonStyle(.automatic)
			} else {
				Text(
					"Add photos here, then long-press the widget on your home screen to choose what's displayed."
				)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)

				if slots.isEmpty {
					Text("Saved Images")
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
						LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
							.frame(height: 8)
						Color.black
						LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
							.frame(height: 8)
					}
				}
			}
				
				PhotosPicker(
					selection: selectedImageSlotItem,
					matching: .images,
					photoLibrary: .shared()
				) {
					Label(
						isSaving ? "Saving..." : "Add Image",
						systemImage: "photo.badge.plus.fill"
					)
					.padding(.vertical, 8)
				}
				.disabled(isSaving)
			}
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	private func slotRow(_ slot: ImageSlotMetadata) -> some View {
		HStack(spacing: 12) {
			slotThumbnail(slot)

			Text(slot.displayName)
				.font(.body)
				.frame(maxWidth: .infinity, alignment: .leading)

			Button(role: .destructive) {
				onDeleteSlot(slot)
			} label: {
				Image(systemName: "trash")
					.font(.body)
					.padding(.trailing, 4)
			}
			.buttonStyle(.borderless)
		}
		.padding(.vertical, 12)
		.padding(.horizontal, 12)
		.background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
	}

	@ViewBuilder
	private func slotThumbnail(_ slot: ImageSlotMetadata) -> some View {
		#if canImport(UIKit)
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
		#else
			thumbnailPlaceholder
		#endif
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

#Preview("Not authorized") {
	ImageWidgetSettingsCard(
		isAuthorized: false,
		isSaving: false,
		slots: [],
		permissionButtonTitle: "Enable Photos",
		selectedImageSlotItem: .constant(nil),
		onPermissionTap: {},
		onDeleteSlot: { _ in }
	)
	.padding()
}

#Preview("Authorized - empty") {
	ImageWidgetSettingsCard(
		isAuthorized: true,
		isSaving: false,
		slots: [],
		permissionButtonTitle: "Enable Photos",
		selectedImageSlotItem: .constant(nil),
		onPermissionTap: {},
		onDeleteSlot: { _ in }
	)
	.padding()
}

#Preview("Authorized - with slots") {
	ImageWidgetSettingsCard(
		isAuthorized: true,
		isSaving: false,
		slots: mockSlots,
		permissionButtonTitle: "Enable Photos",
		selectedImageSlotItem: .constant(nil),
		onPermissionTap: {},
		onDeleteSlot: { _ in }
	)
	.padding()
}

#Preview("Saving in progress") {
	ImageWidgetSettingsCard(
		isAuthorized: true,
		isSaving: true,
		slots: mockSlots,
		permissionButtonTitle: "Enable Photos",
		selectedImageSlotItem: .constant(nil),
		onPermissionTap: {},
		onDeleteSlot: { _ in }
	)
	.padding()
}
