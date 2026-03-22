//
//  QuoteWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 03/21/26.
//

import SwiftUI
import WidgetKit

struct QuoteWidgetView: View {
	@Environment(\.widgetFamily) private var family

	var entry: QuoteEntry

	private var hasQuote: Bool {
		!entry.quote.isEmpty
	}

	// MARK: - Font Sizes

	private var quoteMarkSize: CGFloat {
		switch family {
		case .systemSmall: 24
		case .systemMedium: 28
		case .systemLarge: 32
		default: 24
		}
	}

	private var quoteTextSize: CGFloat {
		switch family {
		case .systemSmall: 32
		case .systemMedium: 36
		case .systemLarge: 40
		default: 32
		}
	}

	// MARK: - Body

	var body: some View {
		if hasQuote {
			quoteView
		} else {
			emptyStateView
		}
	}

	// MARK: - Quote View

	private var quoteView: some View {
		VStack(alignment: .leading, spacing: 0) {
			Image(systemName: "quote.opening")
				.font(.system(size: quoteMarkSize))
				.foregroundStyle(.secondary)
				.padding(.bottom, 6)

			Text(entry.quote)
				.font(.system(size: quoteTextSize))
				.fontWidth(.condensed)
				.fontWeight(.semibold)
				.foregroundStyle(.primary)
				.multilineTextAlignment(.leading)
				.minimumScaleFactor(0.4)
				.frame(
					maxWidth: .infinity,
					maxHeight: .infinity,
					alignment: .topLeading
				)
				.padding(.leading, 2)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
	}

	// MARK: - Empty State

	private var emptyStateView: some View {
		VStack(spacing: 6) {
			Spacer()

			Image(systemName: "quote.bubble.fill")
				.font(.system(size: 32))
				.foregroundStyle(.tertiary)

			Text("Tap and hold to\nedit this widget")
				.font(.system(size: 14, weight: .regular))
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			Spacer()
		}
		.frame(maxWidth: .infinity)
	}
}
