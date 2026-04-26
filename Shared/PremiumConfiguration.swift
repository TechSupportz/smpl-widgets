//
//  PremiumConfiguration.swift
//  smpl-widgets
//
//  Created by OpenCode on 26/04/26.
//

import Foundation

enum PremiumConfiguration {
	static let productID = "unlockWidgets"
	static let productDisplayName = "Unlock All Widgets"

	static let paywallTitle = "Unlock all widgets"
	static let paywallSubtitle =
		"Minimal Calendar stays free. Unlock premium widgets and customize your home screen."
	static let unlockedTitle = "All widgets unlocked"
	static let unlockedSubtitle =
		"Premium widgets are ready to add, configure, and pin to your home screen."

	static let widgetOverlayTitle = "Unlock all widgets"
	static let widgetOverlaySubtitle = "Tap to unlock in app"
	static let restorePurchasesTitle = "Restore Purchases"

	static let purchaseSuccessMessage = "All widgets unlocked."
	static let purchasePendingMessage = "Purchase pending approval."
	static let restoreMissingMessage = "No previous unlock was found for this Apple Account."
	static let unavailableMessage = "Unlock All Widgets is not available yet."
	static let purchaseFailedMessage = "The purchase could not be completed."
	static let restoreFailedMessage = "Restore Purchases could not be completed."
	static let verificationFailedMessage = "The purchase could not be verified."

	static let paywallSectionID = "premiumAccess"
	static let paywallURL = URL(string: "smplwidgets://premium")!

	static let freeWidgetName = "Minimal Calendar"
	static let premiumFeatureNames = [
		"Month Calendar",
		"Events",
		"Weather",
		"Quote",
		"Image",
	]

	static let premiumWidgetKinds: Set<String> = [
		"MonthCalendarWidget",
		"EventWidget",
		"WeatherWidget",
		"QuoteWidget",
		"ImageWidget",
	]

	static var isUnlocked: Bool {
		SharedSettings.shared.isPremiumUnlocked
	}

	static var sharedPriceText: String? {
		SharedSettings.shared.premiumDisplayPrice?.nilIfEmpty
	}

	static func purchaseButtonTitle(priceText: String?) -> String {
		guard let priceText = priceText?.nilIfEmpty else {
			return paywallTitle
		}

		return "Unlock for \(priceText)"
	}
}

private extension String {
	var nilIfEmpty: String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
