//
//  smpl_widgetsApp.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import BackgroundTasks
import SwiftUI
import UIKit
import WidgetKit
import os

@main
struct smpl_widgetsApp: App {
	@State private var purchaseManager = PurchaseManager()
	@State private var isRedirecting = false
	@State private var deepLinkTarget: String?
	@Environment(\.scenePhase) private var scenePhase
	private let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "AppRedirect")
	private let imageWidgetSettingsSectionID = "imageWidgetSettings"

	private let bgTaskID = "com.tnitish.smpl-widgets.refresh"

	init() {
		registerBackgroundTask()
		scheduleBackgroundRefresh()
	}

	var body: some Scene {
		WindowGroup {
			ZStack {
				ContentView(deepLinkTarget: $deepLinkTarget)
					.environment(purchaseManager)

				if isRedirecting {
					Color(.systemBackground).ignoresSafeArea()
					ProgressView()
				}
			}
			.task {
				await purchaseManager.start()
			}
			.onOpenURL { url in
				let scheme = url.scheme ?? ""

				if scheme == "smplwidgets" {
					let destination = url.host ?? ""

					let systemURL: URL?
					switch destination {
					case "calendar":
						isRedirecting = true
						systemURL = URL(string: "calshow://")
					case "weather":
						isRedirecting = true
						systemURL = URL(string: "weather://")
					case "image":
						systemURL = nil
						isRedirecting = false
						deepLinkTarget = imageWidgetSettingsSectionID
					case "permissions":
						systemURL = nil
						isRedirecting = false
						deepLinkTarget = nil
					case "premium":
						systemURL = nil
						isRedirecting = false
						deepLinkTarget = PremiumConfiguration.paywallSectionID
					case "events":
						isRedirecting = true
						let timestamp = Int(Date().timeIntervalSinceReferenceDate)
						systemURL = URL(string: "calshow:\(timestamp)")
					default:
						systemURL = nil
						isRedirecting = false
						deepLinkTarget = nil
						logger.warning("Unknown destination: \(destination)")
					}

					if let systemURL = systemURL {
						UIApplication.shared.open(systemURL) { _ in
							isRedirecting = false
						}
					}
				}
			}
			.onChange(of: scenePhase) { _, newPhase in
				if newPhase == .background {
					scheduleBackgroundRefresh()
				}

				if newPhase == .active {
					Task {
						await purchaseManager.refresh()
					}
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
			guard let task = task as? BGAppRefreshTask else {
				logger.error("Received unexpected background task type for \(bgTaskID)")
				return
			}

			handleBackgroundRefresh(task: task)
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
