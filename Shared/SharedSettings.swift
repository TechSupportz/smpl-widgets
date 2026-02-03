//
//  SharedSettings.swift
//  smpl-widgets
//
//  Created by Nitish on 01/13/26.
//

import Combine
import CoreLocation
import Foundation

struct CachedLocation: Codable {
	let latitude: Double
	let longitude: Double
	let timestamp: Date

	var coordinateString: String {
		let latitudeText = String(format: "%.2f", latitude)
		let longitudeText = String(format: "%.2f", longitude)
		return "\(latitudeText), \(longitudeText)"
	}
	
	var age: TimeInterval {
		Date().timeIntervalSince(timestamp)
	}
	
	func toCLLocation() -> CLLocation {
		CLLocation(latitude: latitude, longitude: longitude)
	}
}

class SharedSettings: ObservableObject {
	static let shared = SharedSettings()

	private let appGroupID = "group.com.tnitish.smpl-widgets"
	private let userDefaults: UserDefaults

	// Keys
	private let lastBackgroundRefreshDateKey = "lastBackgroundRefreshDate"
	private let lastKnownLocationKey = "com.tnitish.smpl-widgets.lastKnownLocation"

	// Fixed refresh interval: 1 hour
	let refreshInterval: TimeInterval = 3600

	var lastBackgroundRefreshDate: Date? {
		get { userDefaults.object(forKey: lastBackgroundRefreshDateKey) as? Date }
		set { userDefaults.set(newValue, forKey: lastBackgroundRefreshDateKey) }
	}
	
	var lastKnownLocation: CachedLocation? {
		guard let data = userDefaults.data(forKey: lastKnownLocationKey) else {
			return nil
		}
		return try? JSONDecoder().decode(CachedLocation.self, from: data)
	}

	private init() {
		self.userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
	}
}
