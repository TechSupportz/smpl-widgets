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
import UIKit
import WidgetKit
import os

struct ContentView: View {
	@Environment(PurchaseManager.self) private var purchaseManager
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "ContentView")
	@Binding private var deepLinkTarget: String?
	@StateObject private var locationService = LocationService()
	@StateObject private var calendarService = CalendarService()
	@StateObject private var imageWidgetPhotoService = ImageWidgetPhotoService()
	@ObservedObject private var sharedSettings = SharedSettings.shared
	@Environment(\.openURL) private var openURL
	@State private var selectedImageSlotItem: PhotosPickerItem?
	@State private var imageSlots: [ImageSlotMetadata] = ImageWidgetStorage.shared.allSlots
	private let imageWidgetSettingsSectionID = "imageWidgetSettings"
	private let premiumAccessSectionID = PremiumConfiguration.paywallSectionID
	private let privacyPolicyURL = URL(string: "https://smpl.tnitish.com/privacy-policy")!

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
							if !purchaseManager.isPremiumUnlocked {
								PremiumUnlockCard()
									.id(premiumAccessSectionID)
									.transition(.opacity)
							}

							appearanceSettingsCard()

							PremiumFeatureGate(
								message: "Location access powers the premium Weather widget."
							) {
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
							}

							PremiumFeatureGate(
								message: "Calendar access powers the premium Events widget."
							) {
								calendarAccessSettingsCard()
							}

							PremiumFeatureGate(
								message: "Save, crop, and configure the premium Image widget here."
							) {
								imageWidgetSettingsCard()
							}
							.id(imageWidgetSettingsSectionID)

							AppInformationCard(privacyPolicyURL: privacyPolicyURL)
						}
						.padding(.horizontal)
					}
					.animation(.easeOut(duration: 0.25), value: purchaseManager.isPremiumUnlocked)
					.onAppear {
						// Refresh status when view appears (e.g., returning from Settings)
						locationService.refreshAuthorizationStatus()
						calendarService.refreshStatus()
						refreshImageSlots()
						scrollToDeepLinkTarget(using: proxy)
					}
					.onChange(of: deepLinkTarget) {
						scrollToDeepLinkTarget(using: proxy)
					}
					.onChange(of: purchaseManager.isPremiumUnlocked) {
						scrollToDeepLinkTarget(using: proxy)
					}
					.onChange(of: sharedSettings.widgetColorScheme) {
						// Reload all widgets when color scheme preference changes
						WidgetCenter.shared.reloadAllTimelines()
					}
					#if DEBUG
						.onChange(of: sharedSettings.isMockDataEnabled) {
							// Reload all widgets when mock data mode changes
							WidgetCenter.shared.reloadAllTimelines()
						}
					#endif
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

			#if DEBUG
				Divider()

				Toggle("Use Mock Data (Screenshots)", isOn: $sharedSettings.isMockDataEnabled)
					.font(.body)
			#endif
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	private func imageWidgetSettingsCard() -> some View {
		ImageWidgetSettingsCard(
			isSaving: imageWidgetPhotoService.isSavingSlot,
			slots: imageSlots,
			selectedImageSlotItem: $selectedImageSlotItem,
			onDeleteSlot: deleteImageSlot,
			onCropSaved: refreshImageSlots
		)
		.onChange(of: selectedImageSlotItem) { _, newValue in
			guard let newValue else { return }
			Task { await saveSelectedImageSlot(from: newValue) }
		}
	}

	private func calendarAccessSettingsCard() -> some View {
		CalendarAccessSettingsCard(
			authorizationStatus: calendarService.authorizationStatus,
			calendars: calendarService.calendars,
			selectedCalendarIDs: selectedDefaultEventCalendarIDs,
			hasCustomDefaultSelection: sharedSettings.defaultEventCalendarIDs != nil,
			permissionButtonTitle: calendarService.isDenied ? "Open Settings" : "Enable Calendar",
			onPermissionTap: {
				if calendarService.isDenied {
					openSettings()
				} else {
					calendarService.requestPermission()
				}
			},
			onSelectionChange: updateDefaultEventCalendars,
			onUseAllCalendars: useAllEventCalendarsByDefault
		)
	}

	// MARK: - Helpers

	private var selectedDefaultEventCalendarIDs: Set<String> {
		if let defaultEventCalendarIDs = sharedSettings.defaultEventCalendarIDs {
			return Set(defaultEventCalendarIDs)
		}

		return Set(calendarService.calendars.map(\.id))
	}

	private func updateDefaultEventCalendars(_ selectedIDs: Set<String>) {
		sharedSettings.defaultEventCalendarIDs = calendarService.calendars
			.map(\.id)
			.filter { selectedIDs.contains($0) }
		WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
	}

	private func useAllEventCalendarsByDefault() {
		sharedSettings.defaultEventCalendarIDs = nil
		WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
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
			logger.error("Failed to save selected image slot: \(error.localizedDescription)")
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
		if let url = URL(string: UIApplication.openSettingsURLString) {
			openURL(url)
		}
	}

	private func relativeTimeString(from date: Date) -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .short
		return formatter.localizedString(for: date, relativeTo: Date())
	}

	private func scrollToDeepLinkTarget(using proxy: ScrollViewProxy) {
		guard let deepLinkTarget else {
			return
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			withAnimation(.smooth) {
				proxy.scrollTo(deepLinkTarget, anchor: .top)
			}

			if self.deepLinkTarget == deepLinkTarget {
				self.deepLinkTarget = nil
			}
		}
	}
}

private struct AppInformationCard: View {
	let privacyPolicyURL: URL

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: "info.circle.fill")
					.font(.title2)
					.foregroundStyle(.blue)

				VStack(alignment: .leading, spacing: 4) {
					Text("About")
						.font(.headline)
					Text("Privacy and app information")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}

				Spacer()
			}

			Link(destination: privacyPolicyURL) {
				HStack(spacing: 12) {
					Label("Privacy Policy", systemImage: "hand.raised.fill")
						.font(.body)

					Spacer()

					Image(systemName: "arrow.up.right")
						.font(.footnote.weight(.semibold))
						.foregroundStyle(.secondary)
						.accessibilityHidden(true)
				}
				.padding(.vertical, 12)
				.padding(.horizontal, 14)
				.background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
			}
			.buttonStyle(.plain)
			.accessibilityHint("Opens in your browser")
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}
}

private struct CalendarAccessSettingsCard: View {
	let authorizationStatus: EKAuthorizationStatus
	let calendars: [CalendarSelectionOption]
	let selectedCalendarIDs: Set<String>
	let hasCustomDefaultSelection: Bool
	let permissionButtonTitle: String
	let onPermissionTap: () -> Void
	let onSelectionChange: (Set<String>) -> Void
	let onUseAllCalendars: () -> Void

	private var isAuthorized: Bool {
		authorizationStatus == .fullAccess
	}

	private var selectionStatusText: String {
		if hasCustomDefaultSelection {
			let selectedCount = selectedCalendarIDs.count
			return "\(selectedCount) of \(calendars.count) selected for event widgets"
		}

		return "All calendars selected for event widgets"
	}

	var body: some View {
		VStack(spacing: 16) {
			HStack(spacing: 16) {
				Image(systemName: authorizationStatus.iconName)
					.font(.title2)
					.foregroundStyle(authorizationStatus.iconColor)

				VStack(alignment: .leading, spacing: 4) {
					Text("Calendar Access")
						.font(.headline)
					Text(authorizationStatus.displayName)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			if isAuthorized {
				calendarSelectionView
			} else {
				Button(action: onPermissionTap) {
					Text(permissionButtonTitle)
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

	@ViewBuilder
	private var calendarSelectionView: some View {
		if calendars.isEmpty {
			Text("No calendars found")
				.font(.callout)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		} else {
			VStack(alignment: .leading, spacing: 12) {
				HStack(alignment: .firstTextBaseline) {
					VStack(alignment: .leading, spacing: 4) {
						Text("Default Event Calendars")
							.font(.callout)
							.fontWeight(.semibold)
						Text(selectionStatusText)
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					Spacer()

					if hasCustomDefaultSelection {
						Button("Use All") {
							onUseAllCalendars()
						}
						.font(.caption)
					}
				}

				VStack(spacing: 8) {
					ForEach(calendars) { calendar in
						calendarRow(calendar)
					}
				}
			}
		}
	}

	private func calendarRow(_ calendar: CalendarSelectionOption) -> some View {
		Toggle(
			isOn: Binding(
				get: {
					selectedCalendarIDs.contains(calendar.id)
				},
				set: { isSelected in
					var updatedSelection = selectedCalendarIDs

					if isSelected {
						updatedSelection.insert(calendar.id)
					} else {
						updatedSelection.remove(calendar.id)
					}

					onSelectionChange(updatedSelection)
				}
			)
		) {
			HStack(spacing: 10) {
				Circle()
					.fill(calendar.color)
					.frame(width: 10, height: 10)

				VStack(alignment: .leading, spacing: 2) {
					Text(calendar.title)
						.font(.body)

					if let sourceDisplayName = calendar.sourceDisplayName {
						Text(sourceDisplayName)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.toggleStyle(.switch)
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
	}
}

#if DEBUG
	#Preview {
		ContentView(deepLinkTarget: .constant(nil))
			.environment(PurchaseManager.previewLocked)
	}
#endif
