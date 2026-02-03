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
	
	private let appGroupID = "group.com.tnitish.smpl-widgets"
	private let persistentCacheKey = "com.tnitish.smpl-widgets.lastKnownLocation"
	private lazy var userDefaults: UserDefaults = {
		UserDefaults(suiteName: appGroupID) ?? .standard
	}()

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

		// Try using CLLocationManager's in-memory cache first
		if let lastLocation = manager.location,
			lastLocation.timestamp.timeIntervalSinceNow > -cachedLocationMaxAge
		{
			logger.debug("Using cached location (age: \(-lastLocation.timestamp.timeIntervalSinceNow)s)")
			savePersistedLocation(lastLocation)
			return lastLocation
		}
		
		// If in-memory cache is stale or unavailable, check persistent cache
		if let persistedLocation = loadPersistedLocation(),
			persistedLocation.age < cachedLocationMaxAge
		{
			logger.debug("Using persisted location cache (age: \(persistedLocation.age)s)")
			return persistedLocation.toCLLocation()
		}

		return try await withTimeout()
	}
	
	private func loadPersistedLocation() -> CachedLocation? {
		guard let data = userDefaults.data(forKey: persistentCacheKey),
			  let cached = try? JSONDecoder().decode(CachedLocation.self, from: data)
		else {
			return nil
		}
		return cached
	}
	
	private func savePersistedLocation(_ location: CLLocation) {
		let cached = CachedLocation(
			latitude: location.coordinate.latitude,
			longitude: location.coordinate.longitude,
			timestamp: location.timestamp
		)
		if let data = try? JSONEncoder().encode(cached) {
			userDefaults.set(data, forKey: persistentCacheKey)
			logger.debug("Saved location to persistent cache")
		}
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
				savePersistedLocation(location)
				resumeAllContinuations(with: .success(location))
			}
		}
	}

	nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		Task { @MainActor in
			logger.error("Location request failed: \(error.localizedDescription)")

		// First try in-memory cache
		if let lastLocation = manager.location,
			lastLocation.timestamp.timeIntervalSinceNow > -fallbackLocationMaxAge
		{
			logger.info("Using fallback cached location (age: \(-lastLocation.timestamp.timeIntervalSinceNow)s)")
			savePersistedLocation(lastLocation)
			resumeAllContinuations(with: .success(lastLocation))
			return
		}
			
			// Then try persistent cache
			if let persistedLocation = loadPersistedLocation(),
				persistedLocation.age < fallbackLocationMaxAge
			{
				logger.info("Using fallback persisted location (age: \(persistedLocation.age)s)")
				resumeAllContinuations(with: .success(persistedLocation.toCLLocation()))
				return
			}
			
			// No valid cache available
			resumeAllContinuations(with: .failure(error))
		}
	}
}
