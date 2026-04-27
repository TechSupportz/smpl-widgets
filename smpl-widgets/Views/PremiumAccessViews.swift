//
//  PremiumAccessViews.swift
//  smpl-widgets
//
//  Created by OpenCode on 26/04/26.
//

import SwiftUI

struct PremiumUnlockCard: View {
	@Environment(PurchaseManager.self) private var purchaseManager

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			header
			lockedBody
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	private var header: some View {
		HStack(spacing: 16) {
			Image(systemName: "lock.rectangle.stack.fill")
				.font(.title2)
				.foregroundStyle(.orange)

			VStack(alignment: .leading, spacing: 4) {
				Text(PremiumConfiguration.paywallTitle)
				.font(.headline)

				Text(PremiumConfiguration.paywallSubtitle)
				.font(.subheadline)
				.foregroundStyle(.secondary)
			}

			Spacer()
		}
	}

	private var lockedBody: some View {
		VStack(alignment: .leading, spacing: 16) {
			LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
				ForEach(PremiumConfiguration.premiumFeatureNames, id: \.self) { feature in
					Label(feature, systemImage: "widget.small")
						.font(.subheadline)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}

			PremiumPurchaseActions()
		}
	}
}

struct PremiumFeatureGate<Content: View>: View {
	@Environment(PurchaseManager.self) private var purchaseManager

	let message: String
	@ViewBuilder var content: Content

	var body: some View {
		ZStack {
			content
				.blur(radius: purchaseManager.isPremiumUnlocked ? 0 : 4)
				.overlay {
					if !purchaseManager.isPremiumUnlocked {
						Color.black.opacity(0.08)
					}
				}
				.allowsHitTesting(purchaseManager.isPremiumUnlocked)

			if !purchaseManager.isPremiumUnlocked {
				PremiumFeatureGateOverlay(message: message)
			}
		}
		.clipShape(.rect(cornerRadius: 24.0))
	}
}

private struct PremiumFeatureGateOverlay: View {
	let message: String

	var body: some View {
		ZStack {
			Rectangle()
				.fill(.regularMaterial)

			VStack(spacing: 12) {
				Image(systemName: "lock.fill")
					.font(.system(size: 26, weight: .semibold))
					.foregroundStyle(.orange)

				Text(PremiumConfiguration.paywallTitle)
					.font(.headline)

				Text(message)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)

				PremiumPurchaseActions()
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 18)
		}
	}
}

private struct PremiumPurchaseActions: View {
	@Environment(PurchaseManager.self) private var purchaseManager

	var body: some View {
		VStack(spacing: 10) {
			Button {
				Task {
					await purchaseManager.purchaseUnlock()
				}
			} label: {
				HStack(spacing: 8) {
					if purchaseManager.isPurchasing {
						ProgressView()
							.controlSize(.small)
					}

					Text(purchaseButtonLabel)
						.font(.headline)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 10)
			}
			.buttonStyle(.glassProminent)
			.disabled(purchaseManager.isBusy)

			Button(PremiumConfiguration.restorePurchasesTitle) {
				Task {
					await purchaseManager.restorePurchases()
				}
			}
			.font(.footnote.weight(.semibold))
			.disabled(purchaseManager.isBusy)

			if purchaseManager.isLoadingProducts && purchaseManager.priceText == nil {
				Text("Fetching current price…")
					.font(.caption)
					.foregroundStyle(.secondary)
			}

			if let statusMessage = purchaseManager.statusMessage {
				StatusMessageBanner(statusMessage: statusMessage)
			}
		}
	}

	private var purchaseButtonLabel: String {
		if purchaseManager.isPurchasing {
			return "Purchasing…"
		}

		return purchaseManager.purchaseButtonTitle
	}
}

private struct StatusMessageBanner: View {
	let statusMessage: PurchaseStatusMessage

	var body: some View {
		HStack(alignment: .center, spacing: 10) {
			Image(systemName: iconName)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(color)

			Text(statusMessage.text)
				.font(.caption)
				.foregroundStyle(.primary)
				.multilineTextAlignment(.leading)

			Spacer(minLength: 0)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(backgroundColor, in: .rect(cornerRadius: 14.0))
	}

	private var iconName: String {
		switch statusMessage.tone {
		case .info:
			return "clock.badge"
		case .error:
			return "exclamationmark.triangle.fill"
		}
	}

	private var color: Color {
		switch statusMessage.tone {
		case .info:
			return .secondary
		case .error:
			return .red
		}
	}

	private var backgroundColor: Color {
		switch statusMessage.tone {
		case .info:
			return .secondary.opacity(0.12)
		case .error:
			return .red.opacity(0.12)
		}
	}
}

#Preview("Locked") {
	PremiumUnlockCard()
		.padding()
		.environment(PurchaseManager.previewLocked)
}

#Preview("Unlocked") {
	PremiumUnlockCard()
		.padding()
		.environment(PurchaseManager.previewUnlocked)
}
