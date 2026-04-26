//
//  PurchaseManager.swift
//  smpl-widgets
//
//  Created by OpenCode on 26/04/26.
//

import Foundation
import Observation
import StoreKit
import WidgetKit

enum PurchaseStatusTone: Equatable {
	case info
	case success
	case error
}

struct PurchaseStatusMessage: Equatable {
	let text: String
	let tone: PurchaseStatusTone
}

@MainActor
@Observable
final class PurchaseManager {
	private(set) var isPremiumUnlocked = PremiumConfiguration.isUnlocked
	private(set) var priceText = PremiumConfiguration.sharedPriceText
	private(set) var isLoadingProducts = false
	private(set) var isSyncingEntitlements = false
	private(set) var isPurchasing = false
	private(set) var isRestoring = false
	private(set) var statusMessage: PurchaseStatusMessage?

	@ObservationIgnored private var unlockProduct: Product?
	@ObservationIgnored private var hasStarted = false
	@ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?

	init() {
		transactionUpdatesTask = observeTransactionUpdates()
	}

	deinit {
		transactionUpdatesTask?.cancel()
	}

	var purchaseButtonTitle: String {
		PremiumConfiguration.purchaseButtonTitle(priceText: priceText)
	}

	var isBusy: Bool {
		isLoadingProducts || isSyncingEntitlements || isPurchasing || isRestoring
	}

	func start() async {
		guard !hasStarted else {
			return
		}

		hasStarted = true
		await refresh()
	}

	func refresh() async {
		await loadProductsIfNeeded(force: unlockProduct == nil)
		await syncEntitlements()
	}

	func purchaseUnlock() async {
		guard !isPurchasing && !isRestoring else {
			return
		}

		statusMessage = nil
		await loadProductsIfNeeded(force: unlockProduct == nil)

		guard let unlockProduct else {
			statusMessage = PurchaseStatusMessage(
				text: PremiumConfiguration.unavailableMessage,
				tone: .error
			)
			return
		}

		isPurchasing = true
		defer {
			isPurchasing = false
		}

		do {
			let purchaseResult = try await unlockProduct.purchase()

			switch purchaseResult {
			case .success(let verificationResult):
				let transaction = try Self.verifiedTransaction(from: verificationResult)
				await transaction.finish()
				await syncEntitlements()

				statusMessage = PurchaseStatusMessage(
					text: isPremiumUnlocked
						? PremiumConfiguration.purchaseSuccessMessage
						: PremiumConfiguration.verificationFailedMessage,
					tone: isPremiumUnlocked ? .success : .error
				)
			case .pending:
				statusMessage = PurchaseStatusMessage(
					text: PremiumConfiguration.purchasePendingMessage,
					tone: .info
				)
			case .userCancelled:
				break
			@unknown default:
				statusMessage = PurchaseStatusMessage(
					text: PremiumConfiguration.purchaseFailedMessage,
					tone: .error
				)
			}
		} catch {
			statusMessage = PurchaseStatusMessage(
				text: Self.message(for: error, fallback: PremiumConfiguration.purchaseFailedMessage),
				tone: .error
			)
		}
	}

	func restorePurchases() async {
		guard !isPurchasing && !isRestoring else {
			return
		}

		statusMessage = nil
		isRestoring = true
		defer {
			isRestoring = false
		}

		do {
			try await AppStore.sync()
			await syncEntitlements()

			statusMessage = PurchaseStatusMessage(
				text: isPremiumUnlocked
					? PremiumConfiguration.purchaseSuccessMessage
					: PremiumConfiguration.restoreMissingMessage,
				tone: isPremiumUnlocked ? .success : .info
			)
		} catch {
			statusMessage = PurchaseStatusMessage(
				text: Self.message(for: error, fallback: PremiumConfiguration.restoreFailedMessage),
				tone: .error
			)
		}
	}

	private func loadProductsIfNeeded(force: Bool) async {
		guard force || unlockProduct == nil else {
			return
		}

		guard !isLoadingProducts else {
			return
		}

		isLoadingProducts = true
		defer {
			isLoadingProducts = false
		}

		do {
			let products = try await Product.products(for: [PremiumConfiguration.productID])
			unlockProduct = products.first(where: { $0.id == PremiumConfiguration.productID })

			if let displayPrice = unlockProduct?.displayPrice {
				persistPriceText(displayPrice)
			}
		} catch {
			unlockProduct = nil
		}
	}

	private func syncEntitlements() async {
		guard !isSyncingEntitlements else {
			return
		}

		isSyncingEntitlements = true
		defer {
			isSyncingEntitlements = false
		}

		var hasUnlock = false

		for await entitlement in Transaction.currentEntitlements {
			do {
				let transaction = try Self.verifiedTransaction(from: entitlement)

				if transaction.productID == PremiumConfiguration.productID,
					transaction.revocationDate == nil
				{
					hasUnlock = true
				}
			} catch {
				continue
			}
		}

		persistUnlockState(hasUnlock)
	}

	private func persistUnlockState(_ isUnlocked: Bool) {
		let previousValue = isPremiumUnlocked
		isPremiumUnlocked = isUnlocked
		SharedSettings.shared.isPremiumUnlocked = isUnlocked

		if previousValue != isUnlocked {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

	private func persistPriceText(_ displayPrice: String) {
		let previousValue = priceText
		priceText = displayPrice
		SharedSettings.shared.premiumDisplayPrice = displayPrice

		if previousValue != displayPrice {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

	private func observeTransactionUpdates() -> Task<Void, Never> {
		Task.detached(priority: .background) { [weak self] in
			for await update in Transaction.updates {
				do {
					let transaction = try Self.verifiedTransaction(from: update)
					await transaction.finish()
				} catch {
					continue
				}

				await self?.syncEntitlements()
			}
		}
	}

	nonisolated private static func verifiedTransaction(
		from verificationResult: VerificationResult<Transaction>
	) throws -> Transaction {
		switch verificationResult {
		case .verified(let transaction):
			return transaction
		case .unverified(_, let error):
			throw error
		}
	}

	private static func message(for error: Error, fallback: String) -> String {
		let localizedDescription = error.localizedDescription.trimmingCharacters(
			in: .whitespacesAndNewlines
		)

		return localizedDescription.isEmpty ? fallback : localizedDescription
	}
}

#if DEBUG
extension PurchaseManager {
	static var previewLocked: PurchaseManager {
		let manager = PurchaseManager()
		manager.transactionUpdatesTask?.cancel()
		manager.priceText = "$4.99"
		manager.isPremiumUnlocked = false
		return manager
	}

	static var previewUnlocked: PurchaseManager {
		let manager = PurchaseManager()
		manager.transactionUpdatesTask?.cancel()
		manager.priceText = "$4.99"
		manager.isPremiumUnlocked = true
		return manager
	}
}
#endif
