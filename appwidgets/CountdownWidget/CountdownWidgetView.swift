//
//  CountdownWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 06/07/26.
//

import SwiftUI
import WidgetKit

struct CountdownWidgetView: View {
	@Environment(\.colorScheme) private var colorScheme

	let entry: CountdownEntry

	var body: some View {
		Group {
			switch entry.state {
			case .unconfigured:
				statusView(
					symbol: "calendar.badge.plus",
					message: "Edit this widget to\nadd a countdown"
				)
			case .invalid(.futureStartDate):
				statusView(
					symbol: "calendar.badge.exclamationmark",
					message: "Start date cannot be\nin the future"
				)
			case .invalid(.endBeforeStart):
				statusView(
					symbol: "calendar.badge.exclamationmark",
					message: "End date must be on or\nafter start date"
				)
			case .configured(let title, let remainingDays, let progress):
				countdownView(
					title: title,
					remainingDays: remainingDays,
					progress: progress
				)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	private func countdownView(
		title: String,
		remainingDays: Int,
		progress: Double
	) -> some View {
		VStack(spacing: 0) {
			Text(title)
				.font(.system(size: 14, weight: .regular))
				.fontWidth(.compressed)
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.minimumScaleFactor(0.65)
				.truncationMode(.tail)
				.frame(maxWidth: .infinity, alignment: .center)
				.offset(y: 6)

			Text(remainingDays, format: .number.grouping(.never))
				.font(.system(size: 220, weight: .bold))
				.fontWidth(.compressed)
				.foregroundStyle(.primary)
				.lineLimit(1)
				.minimumScaleFactor(0.42)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.offset(y: 2)
				.contentTransition(.numericText())

			HStack(alignment: .bottom) {
				CountdownProgressView(
					progress: progress,
					accent: entry.accent.color(for: colorScheme)
				)
				.frame(width: 24, height: 24)
				.offset(y: 2)

				Spacer(minLength: 8)

				Text(remainingDays == 1 ? "day" : "days")
					.font(.system(size: 14, weight: .regular))
					.fontWidth(.compressed)
					.foregroundStyle(.primary)
					.offset(y: -3)
			}
			.offset(y: -8)
		}
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(title)
		.accessibilityValue(
			"\(remainingDays) \(remainingDays == 1 ? "day" : "days") remaining, "
				+ "\(Int((progress * 100).rounded())) percent complete"
		)
	}

	private func statusView(symbol: String, message: LocalizedStringKey) -> some View {
		VStack(spacing: 8) {
			Image(systemName: symbol)
				.font(.system(size: 32, weight: .medium))
				.foregroundStyle(.tertiary)
				.accessibilityHidden(true)

			Text(message)
				.font(.system(size: 14, weight: .regular))
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
		}
		.accessibilityElement(children: .combine)
	}
}

private struct CountdownProgressView: View {
	let progress: Double
	let accent: Color

	var body: some View {
		ZStack {
			CountdownSector(progress: progress)
				.fill(accent)
				.blur(radius: 2)
				.clipShape(.circle)

			Circle()
				.fill(.secondary.opacity(0.12))
				.overlay {
					Circle()
						.stroke(.primary.opacity(0.08), lineWidth: 0.5)
				}
		}
		.accessibilityHidden(true)
	}
}

@Animatable
private struct CountdownSector: Shape {
	var progress: Double

	func path(in rect: CGRect) -> Path {
		let clampedProgress = min(1, max(0, progress))

		if clampedProgress == 1 {
			return Path(ellipseIn: rect)
		}

		guard clampedProgress > 0 else {
			return Path()
		}

		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		var path = Path()
		path.move(to: center)
		path.addLine(to: CGPoint(x: center.x, y: rect.minY))
		path.addArc(
			center: center,
			radius: radius,
			startAngle: .degrees(-90),
			endAngle: .degrees(-90 + (360 * clampedProgress)),
			clockwise: false
		)
		path.closeSubpath()
		return path
	}
}

extension CountdownAccent {
	fileprivate func color(for colorScheme: ColorScheme) -> Color {
		switch self {
		case .red: .red
		case .orange: .orange
		case .yellow: .yellow
		case .green: .green
		case .mint: .mint
		case .teal: .teal
		case .cyan: .cyan
		case .blue: .blue
		case .indigo: .indigo
		case .purple: .purple
		case .pink: .pink
		case .brown: .brown
		case .monochrome: colorScheme == .dark ? .white : .black
		}
	}
}

#Preview("Dark") {
	CountdownWidgetView(entry: .preview)
		.padding(16)
		.frame(width: 170, height: 170)
		.background(.background)
		.environment(\.colorScheme, .dark)
}
