//
//  ImageWidgetSettingsCard.swift
//  smpl-widgets
//
//  Created by Nitish on 22/03/26.
//

import Photos
import PhotosUI
import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct ImageWidgetSettingsCard: View {
	let authorizationStatus: PHAuthorizationStatus
	let isSaving: Bool
	let slots: [ImageSlotMetadata]
	let permissionButtonTitle: String

	var selectedImageSlotItem: Binding<PhotosPickerItem?>
	var onPermissionTap: () -> Void
	var onDeleteSlot: (ImageSlotMetadata) -> Void

	@State private var editingSlot: ImageSlotMetadata? = nil

	private let slotListMaxHeight: CGFloat = 280

	private var isAuthorized: Bool {
		authorizationStatus == .authorized || authorizationStatus == .limited
	}

	private var statusIcon: String {
		switch authorizationStatus {
		case .authorized, .limited:
			return "photo.fill.on.rectangle.fill"
		case .denied, .restricted:
			return "photo.slash"
		case .notDetermined:
			return "photo"
		@unknown default:
			return "photo"
		}
	}

	private var statusColor: Color {
		switch authorizationStatus {
		case .authorized, .limited:
			return .blue
		case .denied, .restricted:
			return .red
		case .notDetermined:
			return .orange
		@unknown default:
			return .gray
		}
	}

	private var statusText: String {
		switch authorizationStatus {
		case .authorized:
			return "Enabled for saved image slots"
		case .limited:
			return "Limited photo access enabled"
		case .denied:
			return "Denied - Enable in Settings"
		case .restricted:
			return "Restricted by system"
		case .notDetermined:
			return "Not configured"
		@unknown default:
			return "Unknown status"
		}
	}

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
		.sheet(item: $editingSlot) { slot in
			#if canImport(UIKit)
				if let data = ImageWidgetStorage.shared.imageData(forSlotID: slot.id),
				   let image = UIImage(data: data)
				{
					ImageCropEditorView(
						slot: slot,
						image: image,
						onSave: {
							WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
						}
					)
				}
			#endif
		}
	}

	private func slotRow(_ slot: ImageSlotMetadata) -> some View {
		HStack(spacing: 12) {
			slotThumbnail(slot)

			Text(slot.displayName)
				.font(.body)
				.frame(maxWidth: .infinity, alignment: .leading)

			Button {
				editingSlot = slot
			} label: {
				Image(systemName: "pencil")
					.font(.body)
			}
			.buttonStyle(.borderless)
			.foregroundStyle(.secondary)

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
		authorizationStatus: .notDetermined,
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
		authorizationStatus: .authorized,
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
		authorizationStatus: .authorized,
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
		authorizationStatus: .authorized,
		isSaving: true,
		slots: mockSlots,
		permissionButtonTitle: "Enable Photos",
		selectedImageSlotItem: .constant(nil),
		onPermissionTap: {},
		onDeleteSlot: { _ in }
	)
	.padding()
}
