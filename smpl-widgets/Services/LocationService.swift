//
//  LocationService.swift
//  smpl-widgets
//
//  Created by Nitish on 7/1/26.
//

import SwiftUI
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
	private let locationManager = CLLocationManager()
	@Published var authorizationStatus: CLAuthorizationStatus?
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		authorizationStatus = locationManager.authorizationStatus
	}
	
	func requestPermission() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func refreshAuthorizationStatus() {
		authorizationStatus = locationManager.authorizationStatus
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		authorizationStatus = manager.authorizationStatus
	}
}
