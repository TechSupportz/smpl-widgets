//
//  LocationFetcher.swift
//  smpl-widgets
//
//  Created by Nitish on 7/1/26.
//

import CoreLocation
import os

@MainActor
class LocationFetcher: NSObject, CLLocationManagerDelegate {
	static let shared = LocationFetcher()

	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "LocationFetcher")
	private let manager = CLLocationManager()
	private var continuations: [CheckedContinuation<CLLocation, Error>] = []
	private var isRequestingLocation = false

	private let locationTimeoutSeconds: UInt64 = 10
	private let cachedLocationMaxAge: TimeInterval = 1800  // 30 minutes for fresh cache
	private let fallbackLocationMaxAge: TimeInterval = 18000  // 5 hours for error fallback

	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
	}

	func getLocation() async throws -> CLLocation {
		switch manager.authorizationStatus {
		case .denied, .restricted:
			throw CLError(.denied)
		case .notDetermined:
			throw CLError(.denied)  // Widget can't request permission
		default:
			break
		}

		if let lastLocation = manager.location,
			lastLocation.timestamp.timeIntervalSinceNow > -cachedLocationMaxAge
		{
			logger.debug("Using cached location (age: \(-lastLocation.timestamp.timeIntervalSinceNow)s)")
			return lastLocation
		}

		return try await withTimeout()
	}

	private func withTimeout() async throws -> CLLocation {
		try await withThrowingTaskGroup(of: CLLocation.self) { group in
			group.addTask {
				try await self.requestLocationAsync()
			}

			group.addTask {
				try await Task.sleep(nanoseconds: self.locationTimeoutSeconds * 1_000_000_000)
				self.logger.warning("Location request timed out after \(self.locationTimeoutSeconds)s")
				throw CLError(.locationUnknown)
			}

			guard let result = try await group.next() else {
				throw CLError(.locationUnknown)
			}
			group.cancelAll()
			return result
		}
	}

	private func requestLocationAsync() async throws -> CLLocation {
		try await withCheckedThrowingContinuation { continuation in
			self.continuations.append(continuation)

			if !self.isRequestingLocation {
				self.isRequestingLocation = true
				self.logger.debug("Requesting fresh location...")
				self.manager.requestLocation()
			} else {
				self.logger.debug("Location request already in progress, waiting...")
			}
		}
	}

	private func resumeAllContinuations(with result: Result<CLLocation, Error>) {
		let waiting = continuations
		continuations.removeAll()
		isRequestingLocation = false

		for continuation in waiting {
			switch result {
			case .success(let location):
				continuation.resume(returning: location)
			case .failure(let error):
				continuation.resume(throwing: error)
			}
		}

		if !waiting.isEmpty {
			logger.debug("Resumed \(waiting.count) waiting continuation(s)")
		}
	}

	nonisolated func locationManager(
		_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
	) {
		Task { @MainActor in
			if let location = locations.last {
				logger.info("Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
				resumeAllContinuations(with: .success(location))
			}
		}
	}

	nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		Task { @MainActor in
			logger.error("Location request failed: \(error.localizedDescription)")

			if let lastLocation = manager.location,
				lastLocation.timestamp.timeIntervalSinceNow > -fallbackLocationMaxAge
			{
				logger.info("Using fallback cached location (age: \(-lastLocation.timestamp.timeIntervalSinceNow)s)")
				resumeAllContinuations(with: .success(lastLocation))
			} else {
				resumeAllContinuations(with: .failure(error))
			}
		}
	}
}
