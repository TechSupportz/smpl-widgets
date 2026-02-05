//
//  Extensions.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

// MARK: - Date Extensions

extension Date {
	/// Returns the start of the current day
	var startOfDay: Date {
		Calendar.current.startOfDay(for: self)
	}

	/// Returns the start of the next day
	var startOfNextDay: Date {
		Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? self
	}
}

// MARK: - View Extensions

extension View {
	/// Applies the standard widget styling with user-selected color scheme preference
	func alwaysWhiteWidgetStyle() -> some View {
		let colorScheme = SharedSettings.shared.widgetColorScheme

		return
			self
			.applyContainerBackground(colorScheme)
			.applyColorScheme(colorScheme)
	}

	@ViewBuilder
	private func applyContainerBackground(_ scheme: WidgetColorScheme) -> some View {
		switch scheme {
		case .light:
			self.containerBackground(.white, for: .widget)
		case .dark:
			self.containerBackground(.background, for: .widget)
		case .system:
			self.containerBackground(.background, for: .widget)
		}
	}
	
	@ViewBuilder
	private func applyColorScheme(_ scheme: WidgetColorScheme) -> some View {
		_ColorSchemeApplier(scheme: scheme, content: self)
	}
}

private struct _ColorSchemeApplier<Content: View>: View {
	@Environment(\.showsWidgetContainerBackground) var showsBackground
	let scheme: WidgetColorScheme
	let content: Content
	
	var body: some View {
		Group {
			if !showsBackground {
				content
			} else {
				switch scheme {
				case .light:
					content.environment(\.colorScheme, .light)
				case .dark:
					content.environment(\.colorScheme, .dark)
				case .system:
					content
				}
			}
		}
	}
}
