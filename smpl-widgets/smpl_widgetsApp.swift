//
//  smpl_widgetsApp.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import os

@main
struct smpl_widgetsApp: App {
	@State private var isRedirecting = false
	@State private var launchedFromWidget = false
	@State private var isCheckingLaunchSource = true
	@Environment(\.scenePhase) private var scenePhase
	let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "AppRedirect")

	var body: some Scene {
		WindowGroup {
			ZStack {
				// Only show ContentView if confirmed NOT launched from widget
				if !launchedFromWidget && !isRedirecting && !isCheckingLaunchSource {
					ContentView()
				}

				// Show loading during check, redirect, or widget launch
				if isRedirecting || launchedFromWidget || isCheckingLaunchSource {
					Color(.systemBackground).ignoresSafeArea()
					ProgressView()
				}
			}
			.onAppear {
				// Give onOpenURL time to fire before showing ContentView
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					if !launchedFromWidget {
						logger.info("⏱️ No widget URL received, showing ContentView")
						isCheckingLaunchSource = false
					}
				}
			}
			.onOpenURL { url in
				let scheme = url.scheme ?? ""

				logger.info("onOpenURL triggered - URL: \(url.absoluteString), scheme: \(scheme)")

				if scheme == "smplwidgets" {
					let destination = url.host ?? ""
					logger.info("Custom URL received - destination: \(destination)")

					// Mark as launched from widget
					launchedFromWidget = true
					isCheckingLaunchSource = false
					isRedirecting = true

					let systemURL: URL?
					switch destination {
					case "calendar":
						systemURL = URL(string: "calshow://")
						logger.info("Redirecting to Calendar app")
					case "weather":
						systemURL = URL(string: "weather://")
						logger.info("Redirecting to Weather app")
					default:
						systemURL = nil
						logger.warning("Unknown destination: \(destination)")
					}

					if let systemURL = systemURL {
						logger.info("Opening system URL: \(systemURL.absoluteString)")
						UIApplication.shared.open(systemURL)
					}
				} else {
					logger.warning("Scheme '\(scheme)' is not 'smplwidgets'")
				}
			}
			.onChange(of: scenePhase) { oldPhase, newPhase in
				logger.info(
					"scenePhase changed: \(String(describing: oldPhase)) -> \(String(describing: newPhase)), launchedFromWidget: \(launchedFromWidget)"
				)

				if newPhase == .active && (oldPhase == .background || oldPhase == .inactive)
					&& launchedFromWidget
				{
					// Terminate the app when returning from widget-initiated redirect
					logger.info("Returning from widget redirect - terminating app")
					exit(0)
				}
			}
		}
	}
}
