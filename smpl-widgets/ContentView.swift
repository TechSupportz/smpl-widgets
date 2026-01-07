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
	let locationManager = CLLocationManager()
	@StateObject private var appLocationService = LocationService()

	var isLocationAuthorized: Bool {
		appLocationService.authorizationStatus == .authorizedWhenInUse
	}
	
	

	var body: some View {
		VStack {
			HStack {
				Image(systemName: "location.fill")
					.imageScale(.medium)
				Text("Location services: \(isLocationAuthorized ? "Enabled" : "Disabled")")
			}
			.padding()
			if !isLocationAuthorized {
				Button("Enable Location Permissions") {
					appLocationService.requestPermission()
				}
				.buttonStyle(.glassProminent)
			} else if let location = appLocationService.location {
				Group {
					Text("Lat: \(location.coordinate.latitude)")
					Text("Lng: \(location.coordinate.longitude)")
					Text("Accuracy: +/- \(location.horizontalAccuracy)m")
					Text("Timestamp: \(location.timestamp.formatted())")
				}
				.font(.system(.body, design: .monospaced))
			} else {
				Text("⚠️ Location is NIL")
					.foregroundColor(.red)
					.fontWeight(.bold)
				
				Text("Status: \(appLocationService.authorizationStatus?.rawValue ?? -1)")
				
				Button("Force Request Location") {
					appLocationService.requestPermission()
				}
			}
			Button(action: {
				print("🔄 Requesting Widget Reload...")
				
				// 🚀 THE MAGIC LINE
				WidgetCenter.shared.reloadAllTimelines()
				
			}) {
				Label("Force Widget Refresh", systemImage: "arrow.clockwise.circle.fill")
					.font(.headline)
					.padding()
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(10)
			}
				
			
		}
	}
}

#Preview {
	ContentView()
}
