//
//  LocationFetcher.swift
//  smpl-widgets
//
//  Created by Nitish on 7/1/26.
//

import CoreLocation

@MainActor
class LocationFetcher: NSObject, CLLocationManagerDelegate {
	private let manager = CLLocationManager()
	private var continuation: CheckedContinuation<CLLocation, Error>?
	
	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
	}
	
	func getLocation() async throws -> CLLocation {
		if let lastLocation = manager.location,
			lastLocation.timestamp.timeIntervalSinceNow > -300 { // valid within last 5 mins
			return lastLocation
		}
		
		return try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
			manager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = locations.last {
			continuation?.resume(returning: location)
			continuation = nil
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		if let lastLocation = manager.location {
			continuation?.resume(returning: lastLocation)
		} else {
			continuation?.resume(throwing: error)
		}
		continuation = nil
	}
}
