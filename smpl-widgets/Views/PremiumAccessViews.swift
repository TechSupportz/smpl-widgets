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

			if !purchaseManager.isPremiumUnlocked {
				lockedBody
			}
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 24)
		.glassEffect(in: .rect(cornerRadius: 24.0))
	}

	private var header: some View {
		HStack(spacing: 16) {
			Image(systemName: purchaseManager.isPremiumUnlocked ? "checkmark.seal.fill" : "lock.rectangle.stack.fill")
				.font(.title2)
				.foregroundStyle(purchaseManager.isPremiumUnlocked ? .green : .orange)

			VStack(alignment: .leading, spacing: 4) {
				Text(
					purchaseManager.isPremiumUnlocked
						? PremiumConfiguration.unlockedTitle
						: PremiumConfiguration.paywallTitle
				)
				.font(.headline)

				Text(
					purchaseManager.isPremiumUnlocked
						? PremiumConfiguration.unlockedSubtitle
						: PremiumConfiguration.paywallSubtitle
				)
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
				Text(statusMessage.text)
					.font(.caption)
					.foregroundStyle(color(for: statusMessage.tone))
					.multilineTextAlignment(.center)
			}
		}
	}

	private var purchaseButtonLabel: String {
		if purchaseManager.isPurchasing {
			return "Purchasing…"
		}

		return purchaseManager.purchaseButtonTitle
	}

	private func color(for tone: PurchaseStatusTone) -> Color {
		switch tone {
		case .info:
			return .secondary
		case .success:
			return .green
		case .error:
			return .red
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
