//
//  ContentView.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import CoreLocation
import EventKit
import Foundation
import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct ContentView: View {
	@StateObject private var locationService = LocationService()
	@StateObject private var calendarService = CalendarService()
	@ObservedObject private var sharedSettings = SharedSettings.shared
	@Environment(\.openURL) private var openURL

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
							buttonTitle: locationService.authorizationStatus == .denied
								? "Open Settings" : "Enable Location",
							buttonAction: {
								if locationService.authorizationStatus == .denied {
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
					}
					.padding(.horizontal)
				}
				.onAppear {
					// Refresh status when view appears (e.g., returning from Settings)
					calendarService.refreshStatus()
				}
				.onChange(of: sharedSettings.widgetColorScheme) { oldValue, newValue in
					// Reload all widgets when color scheme preference changes
					WidgetCenter.shared.reloadAllTimelines()
				}
				.contentMargins(.bottom, 96)
				.contentMargins(.top, 24)
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
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	// MARK: - Helpers

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
}

#Preview {
	ContentView()
}
