//
//  LocationFetcher.swift
//  smpl-widgets
//
//  Created by Nitish on 7/1/26.
//

import CoreLocation

@MainActor
class LocationFetcher: NSObject, CLLocationManagerDelegate {
	static let shared = LocationFetcher()

	private let manager = CLLocationManager()
	private var continuation: CheckedContinuation<CLLocation, Error>?

	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
	}

	func getLocation() async throws -> CLLocation {
		// Check authorization
		switch manager.authorizationStatus {
		case .denied, .restricted:
			throw CLError(.denied)
		case .notDetermined:
			throw CLError(.denied) // Widget can't request permission
		default:
			break
		}

		// Return cached location if valid (30 min window)
		if let lastLocation = manager.location,
			lastLocation.timestamp.timeIntervalSinceNow > -1800
		{
			return lastLocation
		}

		// Request fresh location
		return try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
			manager.requestLocation()
		}
	}

	nonisolated func locationManager(
		_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
	) {
		Task { @MainActor in
			if let location = locations.last {
				continuation?.resume(returning: location)
				continuation = nil
			}
		}
	}

	nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		Task { @MainActor in
			if let lastLocation = manager.location {
				// Fallback to any cached location
				continuation?.resume(returning: lastLocation)
			} else {
				continuation?.resume(throwing: error)
			}
			continuation = nil
		}
	}
}
