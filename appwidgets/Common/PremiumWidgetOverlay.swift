//
//  PremiumWidgetOverlay.swift
//  appwidgets
//
//  Created by OpenCode on 26/04/26.
//

import SwiftUI
import WidgetKit

extension View {
	func premiumLockedWidgetStyle(isLocked: Bool, priceText: String? = nil) -> some View {
		modifier(PremiumLockedWidgetModifier(isLocked: isLocked, priceText: priceText))
	}
}

private struct PremiumLockedWidgetModifier: ViewModifier {
	let isLocked: Bool
	let priceText: String?

	func body(content: Content) -> some View {
		ZStack {
			content
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.blur(radius: isLocked ? 10 : 0)
				.opacity(isLocked ? 0.3 : 1)

			if isLocked {
				PremiumWidgetOverlay(priceText: priceText)
			}
		}
	}
}

private struct PremiumWidgetOverlay: View {
	private let priceText: String?

	init(priceText: String? = PremiumConfiguration.sharedPriceText) {
		self.priceText = priceText
	}

	var body: some View {
		ZStack {

			VStack(spacing: 8) {
				Image(systemName: "lock.fill")
					.font(.system(size: 20, weight: .semibold))

				Text(PremiumConfiguration.widgetOverlayTitle)
					.font(.system(size: 14, weight: .semibold))
					.multilineTextAlignment(.center)

				Text("Tap to purchase in-app")
					.font(.system(size: 12, weight: .medium))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}
