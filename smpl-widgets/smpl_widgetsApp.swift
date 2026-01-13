//
//  smpl_widgetsApp.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import BackgroundTasks
import SwiftUI
import WidgetKit
import os

@main
struct smpl_widgetsApp: App {
	@State private var isRedirecting = false
	@State private var launchedFromWidget = false
	@State private var isCheckingLaunchSource = true
	@Environment(\.scenePhase) private var scenePhase
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "AppRedirect")

	private let bgTaskID = "com.tnitish.smpl-widgets.refresh"

	init() {
		registerBackgroundTask()
		scheduleBackgroundRefresh()
	}

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
						isCheckingLaunchSource = false
					}
				}
			}
			.onOpenURL { url in
				let scheme = url.scheme ?? ""

				if scheme == "smplwidgets" {
					let destination = url.host ?? ""

					// Mark as launched from widget
					launchedFromWidget = true
					isCheckingLaunchSource = false
					isRedirecting = true

					let systemURL: URL?
					switch destination {
					case "calendar":
						systemURL = URL(string: "calshow://")
					case "weather":
						systemURL = URL(string: "weather://")
					case "events":
						// Just open the main app
						systemURL = nil
						launchedFromWidget = false
						isRedirecting = false
					default:
						systemURL = nil
						logger.warning("Unknown destination: \(destination)")
					}

					if let systemURL = systemURL {
						UIApplication.shared.open(systemURL)
					}
				}
			}
			.onChange(of: scenePhase) { oldPhase, newPhase in
				if newPhase == .active && (oldPhase == .background || oldPhase == .inactive)
					&& launchedFromWidget
				{
					// Terminate the app when returning from widget-initiated redirect
					exit(0)
				}

				if newPhase == .background {
					scheduleBackgroundRefresh()
				}
			}
		}
	}

	// MARK: - Background Tasks

	private func registerBackgroundTask() {
		BGTaskScheduler.shared.register(
			forTaskWithIdentifier: bgTaskID,
			using: nil
		) { task in
			handleBackgroundRefresh(task: task as! BGAppRefreshTask)
		}
	}

	private func handleBackgroundRefresh(task: BGAppRefreshTask) {
		task.expirationHandler = {
			task.setTaskCompleted(success: false)
		}

		// Reload widget
		WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
		SharedSettings.shared.lastBackgroundRefreshDate = Date()

		task.setTaskCompleted(success: true)

		// Schedule next refresh
		scheduleBackgroundRefresh()
	}

	private func scheduleBackgroundRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: bgTaskID)
		request.earliestBeginDate = Date(
			timeIntervalSinceNow: SharedSettings.shared.refreshInterval
		)

		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			logger.error("❌ Failed to schedule background refresh: \(error)")
		}
	}
}
