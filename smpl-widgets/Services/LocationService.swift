//
//  LocationService.swift
//  smpl-widgets
//
//  Created by Nitish on 7/1/26.
//

import SwiftUI
import CoreLocation
internal import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
	private let locationManager = CLLocationManager()
	@Published var authorizationStatus: CLAuthorizationStatus?
	
	// ------------------------------------
	// ADD THIS PART:
	// ------------------------------------
	var location: CLLocation? {
		return locationManager.location
	}
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
	}
	
	func requestPermission() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	// Helper to force an update if needed
	func requestLocation() {
		locationManager.requestLocation()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		authorizationStatus = manager.authorizationStatus
	}
	
	// Allow the manager to update us on location changes (needed for some flows)
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		// We don't strictly need to do anything here if we just access .location directly,
		// but it's good practice to have the method.
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Location error: \(error.localizedDescription)")
	}
}
