//
//  SharedSettings.swift
//  smpl-widgets
//
//  Created by Nitish on 01/13/26.
//

import Combine
import Foundation

class SharedSettings: ObservableObject {
	static let shared = SharedSettings()

	private let appGroupID = "group.com.tnitish.smpl-widgets"
	private let userDefaults: UserDefaults

	// Keys
	private let lastBackgroundRefreshDateKey = "lastBackgroundRefreshDate"

	// Fixed refresh interval: 1 hour
	let refreshInterval: TimeInterval = 3600

	var lastBackgroundRefreshDate: Date? {
		get { userDefaults.object(forKey: lastBackgroundRefreshDateKey) as? Date }
		set { userDefaults.set(newValue, forKey: lastBackgroundRefreshDateKey) }
	}

	private init() {
		self.userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
	}
}
