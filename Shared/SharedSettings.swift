//
//  SharedSettings.swift
//  smpl-widgets
//
//  Created by Nitish on 01/13/26.
//

import Combine
import CoreLocation
import Foundation

enum WidgetColorScheme: String, Codable, CaseIterable {
	case system
	case light
	case dark
	
	var displayName: String {
		switch self {
		case .system: return "System Default"
		case .light: return "Light Mode"
		case .dark: return "Dark Mode"
		}
	}
	
	var description: String {
		switch self {
		case .system: return "Match device appearance"
		case .light: return "Always light"
		case .dark: return "Always dark"
		}
	}
}

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
	private let widgetColorSchemeKey = "com.tnitish.smpl-widgets.widgetColorScheme"

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
	
	var widgetColorScheme: WidgetColorScheme {
		get {
			guard let rawValue = userDefaults.string(forKey: widgetColorSchemeKey),
				  let scheme = WidgetColorScheme(rawValue: rawValue) else {
				return .system
			}
			return scheme
		}
		set {
			objectWillChange.send()
			userDefaults.set(newValue.rawValue, forKey: widgetColorSchemeKey)
			userDefaults.synchronize()
		}
	}

	private init() {
		self.userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
	}
}
