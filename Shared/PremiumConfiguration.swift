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
		"Minimal Calendar is included free. One purchase unlocks everything else"
	static let unlockedTitle = "You're all set"
	static let unlockedSubtitle =
		"All widgets are yours. Add them to your home screen anytime."

	static let widgetOverlayTitle = "Unlock all widgets"
	static let restorePurchasesTitle = "Restore Purchase"

	static let purchaseSuccessMessage = "All widgets unlocked."
	static let purchasePendingMessage = "Purchase submitted — widgets will unlock once it clears."
	static let restoreMissingMessage = "No purchase found for this Apple Account."
	static let unavailableMessage = "Purchase is not available right now. Try again later."
	static let purchaseFailedMessage = "Something went wrong. Your card was not charged."
	static let restoreFailedMessage = "Couldn't restore your purchase. Try again."
	static let verificationFailedMessage = "Purchase verification failed. Contact support if this persists."

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

		return "Unlock all widgets for \(priceText)"
	}
}

private extension String {
	var nilIfEmpty: String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
