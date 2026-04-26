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
				.blur(radius: isLocked ? 2 : 0)

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

	private var buttonTitle: String {
		PremiumConfiguration.purchaseButtonTitle(priceText: priceText)
	}

	var body: some View {
		ZStack {
			Color.black.opacity(0.14)

			VStack(spacing: 8) {
				Image(systemName: "lock.fill")
					.font(.system(size: 20, weight: .semibold))
					.foregroundStyle(.yellow)

				Text(PremiumConfiguration.widgetOverlayTitle)
					.font(.system(size: 13, weight: .semibold))
					.multilineTextAlignment(.center)

				Text(buttonTitle)
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)

				Text(PremiumConfiguration.widgetOverlaySubtitle)
					.font(.system(size: 10, weight: .regular))
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 12)
			.background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}
