//
//  ContentView.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import CoreLocation
import EventKit
import Foundation
import PhotosUI
import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct ContentView: View {
	@Binding private var deepLinkTarget: String?
	@StateObject private var locationService = LocationService()
	@StateObject private var calendarService = CalendarService()
	@StateObject private var imageWidgetPhotoService = ImageWidgetPhotoService()
	@ObservedObject private var sharedSettings = SharedSettings.shared
	@Environment(\.openURL) private var openURL
	@State private var selectedImageSlotItem: PhotosPickerItem?
	@State private var imageSlots: [ImageSlotMetadata] = ImageWidgetStorage.shared.allSlots
	private let imageWidgetSettingsSectionID = "imageWidgetSettings"

	init(deepLinkTarget: Binding<String?> = .constant(nil)) {
		_deepLinkTarget = deepLinkTarget
	}

	// MARK: - Location Helpers

	private var isLocationAuthorized: Bool {
		locationService.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse
			|| locationService.authorizationStatus == CLAuthorizationStatus.authorizedAlways
	}

	private var locationStatusIcon: String {
		switch locationService.authorizationStatus {
		case .authorizedWhenInUse, .authorizedAlways:
			return "location.fill"
		case .denied, .restricted:
			return "location.slash.fill"
		case .notDetermined, .none:
			return "location.circle"
		@unknown default:
			return "location.circle"
		}
	}

	private var locationStatusColor: Color {
		switch locationService.authorizationStatus {
		case .authorizedWhenInUse, .authorizedAlways:
			return .blue
		case .denied, .restricted:
			return .red
		case .notDetermined, .none:
			return .orange
		@unknown default:
			return .gray
		}
	}

	private var locationStatusText: String {
		switch locationService.authorizationStatus {
		case .authorizedWhenInUse, .authorizedAlways:
			return "Enabled for weather widgets"
		case .denied:
			return "Denied - Enable in Settings"
		case .restricted:
			return "Restricted by system"
		case .notDetermined, .none:
			return "Not configured"
		@unknown default:
			return "Unknown status"
		}
	}

	private var isLocationDeniedOrRestricted: Bool {
		locationService.authorizationStatus == .denied
			|| locationService.authorizationStatus == .restricted
	}

	private var cachedLocationText: String {
		guard let cachedLocation = SharedSettings.shared.lastKnownLocation else {
			return "No cached location"
		}
		let updatedText = relativeTimeString(from: cachedLocation.timestamp)
		return "Last cached: \(cachedLocation.coordinateString) • \(updatedText)"
	}

	private var imageWidgetPermissionButtonTitle: String {
		let status = imageWidgetPhotoService.authorizationStatus
		if status == .denied || status == .restricted {
			return "Open Settings"
		}
		return "Enable Photos"
	}

	private var isPhotosDeniedOrRestricted: Bool {
		let status = imageWidgetPhotoService.authorizationStatus
		return status == .denied || status == .restricted
	}

	var body: some View {
		ZStack(alignment: .bottom) {
			VStack(spacing: 24) {
				// App Header
				VStack(spacing: 8) {
					Image(systemName: "widget.small")
						.font(.system(size: 60))

					Text("smpl.widgets")
						.font(.title)
						.fontWeight(.black)
						.italic()

					Text("Simple and Minimal Homescreen widgets")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.padding(.top, 24)

				ScrollViewReader { proxy in
					ScrollView(.vertical) {
						VStack(spacing: 16) {
							appearanceSettingsCard()

							// Permission Cards
							// Location Permission Card
							permissionCard(
								icon: locationStatusIcon,
								iconColor: locationStatusColor,
								title: "Location Access",
								subtitle: locationStatusText,
								secondaryText: cachedLocationText,
								showButton: !isLocationAuthorized,
								buttonTitle: isLocationDeniedOrRestricted
									? "Open Settings" : "Enable Location",
								buttonAction: {
									if isLocationDeniedOrRestricted {
										openSettings()
									} else {
										locationService.requestPermission()
									}
								}
							)

							// Calendar Permission Card
							permissionCard(
								icon: calendarService.authorizationStatus.iconName,
								iconColor: calendarService.authorizationStatus.iconColor,
								title: "Calendar Access",
								subtitle: calendarService.authorizationStatus.displayName,
								showButton: !calendarService.isAuthorized,
								buttonTitle: calendarService.isDenied
									? "Open Settings" : "Enable Calendar",
								buttonAction: {
									if calendarService.isDenied {
										openSettings()
									} else {
										calendarService.requestPermission()
									}
								}
							)

							imageWidgetSettingsCard()
								.id(imageWidgetSettingsSectionID)
						}
						.padding(.horizontal)
					}
					.onAppear {
						// Refresh status when view appears (e.g., returning from Settings)
						locationService.refreshAuthorizationStatus()
						calendarService.refreshStatus()
						imageWidgetPhotoService.refreshAuthorizationStatus()
						refreshImageSlots()
						scrollToDeepLinkTarget(using: proxy)
					}
					.onChange(of: deepLinkTarget) {
						scrollToDeepLinkTarget(using: proxy)
					}
					.onChange(of: sharedSettings.widgetColorScheme) {
						// Reload all widgets when color scheme preference changes
						WidgetCenter.shared.reloadAllTimelines()
					}
					.onChange(of: sharedSettings.isMockDataEnabled) {
						// Reload all widgets when mock data mode changes
						WidgetCenter.shared.reloadAllTimelines()
					}
					.contentMargins(.bottom, 96)
					.contentMargins(.top, 32)
					.mask(
						VStack(spacing: 0) {
							LinearGradient(
								colors: [.clear, .black],
								startPoint: .top,
								endPoint: .bottom
							)
							.frame(height: 40)

							Color.black // Middle fully visible

							LinearGradient(
								colors: [.black, .clear],
								startPoint: .top,
								endPoint: .bottom
							)
							.frame(height: 16)
						}
					)
				}
			}
			// Widget Refresh Button
			Button(action: {
				WidgetCenter.shared.reloadAllTimelines()
			}) {
				Label("Refresh Widgets", systemImage: "arrow.clockwise")
					.font(.headline)
					.padding(.vertical, 12)
					.padding(.horizontal, 24)
			}
			.buttonStyle(.glassProminent)
			.padding(.horizontal)
		}
	}

	// MARK: - Permission Card Component

	private func permissionCard(
		icon: String,
		iconColor: Color,
		title: String,
		subtitle: String,
		secondaryText: String? = nil,
		showButton: Bool,
		buttonTitle: String,
		buttonAction: @escaping () -> Void
	) -> some View {
		VStack(spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: icon)
					.font(.title2)
					.foregroundStyle(iconColor)

				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.headline)
					Text(subtitle)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			if let secondaryText {
				Text(secondaryText)
					.font(.caption)
					.foregroundStyle(.secondary)
					.fontDesign(.monospaced)
			}

			if showButton {
				Button(action: buttonAction) {
					Text(buttonTitle)
						.font(.headline)
						.padding(.vertical, 8)
				}
				.buttonStyle(.automatic)
			}
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	// MARK: - Appearance Settings Card

	private func appearanceSettingsCard() -> some View {
		VStack(spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: "circle.lefthalf.filled")
					.font(.title2)
					.foregroundStyle(.blue)

				VStack(alignment: .leading, spacing: 4) {
					Text("Widget Appearance")
						.font(.headline)
					Text("Choose color scheme for widgets")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			Picker("Color Scheme", selection: $sharedSettings.widgetColorScheme) {
				ForEach(WidgetColorScheme.allCases, id: \.self) { scheme in
					Text(scheme.displayName)
						.font(.body)
						.tag(scheme)
				}
			}
			.labelsHidden()
			.pickerStyle(.menu)

			Divider()

			Toggle("Use Mock Data (Screenshots)", isOn: $sharedSettings.isMockDataEnabled)
				.font(.body)
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	private func imageWidgetSettingsCard() -> some View {
		ImageWidgetSettingsCard(
			authorizationStatus: imageWidgetPhotoService.authorizationStatus,
			isSaving: imageWidgetPhotoService.isSavingSlot,
			slots: imageSlots,
			permissionButtonTitle: imageWidgetPermissionButtonTitle,
			selectedImageSlotItem: $selectedImageSlotItem,
			onPermissionTap: {
				Task { await requestImageWidgetPhotoPermission() }
			},
			onDeleteSlot: deleteImageSlot
		)
		.onChange(of: selectedImageSlotItem) { _, newValue in
			guard let newValue else { return }
			Task { await saveSelectedImageSlot(from: newValue) }
		}
	}

	// MARK: - Helpers

	private func requestImageWidgetPhotoPermission() async {
		if isPhotosDeniedOrRestricted {
			openSettings()
			return
		}

		let granted = await imageWidgetPhotoService.requestPermissionIfNeeded()
		guard granted else {
			
			return
		}

	}

	private func saveSelectedImageSlot(from item: PhotosPickerItem) async {
		defer {
			selectedImageSlotItem = nil
		}

		do {
			let _ = try await imageWidgetPhotoService.createSlot(from: item, quality: 0.85)
			withAnimation {
				refreshImageSlots()
			}
			WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
		} catch {
			print(error.localizedDescription)
		}
	}

	private func deleteImageSlot(_ slot: ImageSlotMetadata) {
		ImageWidgetStorage.shared.deleteSlot(id: slot.id)
		withAnimation {
			refreshImageSlots()
		}
		WidgetCenter.shared.reloadTimelines(ofKind: "ImageWidget")
	}

	private func refreshImageSlots() {
		imageSlots = ImageWidgetStorage.shared.allSlots
	}

	private func openSettings() {
		#if canImport(UIKit)
			if let url = URL(string: UIApplication.openSettingsURLString) {
				openURL(url)
			}
		#endif
	}

	private func relativeTimeString(from date: Date) -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .short
		return formatter.localizedString(for: date, relativeTo: Date())
	}

	private func scrollToDeepLinkTarget(using proxy: ScrollViewProxy) {
		guard deepLinkTarget == imageWidgetSettingsSectionID else { return }

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			withAnimation(.smooth) {
				proxy.scrollTo(imageWidgetSettingsSectionID, anchor: .top)
			}
			deepLinkTarget = nil
		}
	}
}

#Preview {
	ContentView(deepLinkTarget: .constant(nil))
}
