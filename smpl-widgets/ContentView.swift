//
//  ContentView.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import CoreLocation
import SwiftUI
import WidgetKit

struct ContentView: View {
	@StateObject private var locationService = LocationService()

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

	var body: some View {
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
			.padding(.top, 40)

			// Location Permission Card
			VStack(spacing: 16) {
				HStack(spacing: 16) {
					Image(systemName: locationStatusIcon)
						.font(.title2)
						.foregroundStyle(locationStatusColor)

					VStack(alignment: .leading, spacing: 4) {
						Text("Location Access")
							.font(.headline)
						Text(locationStatusText)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					Spacer()
				}

				if !isLocationAuthorized {
					Button(action: {
						locationService.requestPermission()
					}) {
						Text("Enable Location")
							.font(.headline)
							.padding(.vertical, 8)
					}
					.buttonStyle(.automatic)
				}
			}
			.padding(.vertical, 16)
			.padding(.horizontal, 24)
			.glassEffect(in: .rect(cornerRadius: 24.0))
			.padding(.horizontal)

			Spacer()

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
			.padding(.bottom, 24)
		}
	}
}

#Preview {
	ContentView()
}
