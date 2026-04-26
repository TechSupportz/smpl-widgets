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
	@Environment(\.redactionReasons) private var redactionReasons

	var entry: QuoteEntry

	private var hasQuote: Bool {
		!entry.quote.isEmpty
	}

	private var isPlaceholder: Bool {
		redactionReasons.contains(.placeholder) || entry.isPlaceholder
	}

	// MARK: - Font Sizes

	private var quoteMarkSize: CGFloat {
		switch family {
		case .systemSmall: 20
		case .systemMedium: 22
		case .systemLarge: 36
		default: 20
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
		if isPlaceholder || hasQuote {
			quoteView
		} else {
			emptyStateView
		}
	}

	// MARK: - Quote View

	private var quoteView: some View {
		VStack(alignment: .leading, spacing: 0) {
			Image("QuoteMark")
				.resizable()
				.renderingMode(.template)
				.aspectRatio(contentMode: .fit)
				.frame(height: quoteMarkSize)
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

			Text("Press and hold to\nedit this widget")
				.font(.system(size: 14, weight: .regular))
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			Spacer()
		}
		.frame(maxWidth: .infinity)
	}
}
