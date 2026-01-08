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
	/// Applies the standard widget styling
	func alwaysWhiteWidgetStyle() -> some View {
		self
			.containerBackground(.white, for: .widget)
			.environment(\.colorScheme, .light)
	}
}
