//
//  DateTimeControlWidget.swift
//  appwidgets
//
//  Created by Nitish on 10/05/26.
//

import AppIntents
import SwiftUI
import WidgetKit

struct DateTimeControlWidget: ControlWidget {
	let kind: String = "DateTimeControlWidget"

	var body: some ControlWidgetConfiguration {
		StaticControlConfiguration(kind: kind) {
			ControlWidgetButton(action: DateTimeControlIntent()) {
				Label {
					VStack {
						Text(.now, format: .dateTime.day().month(.defaultDigits).year(.twoDigits))
						Text(.now, format: .dateTime.weekday(.wide))
					}
				} icon: {
					Image(systemName: "calendar.circle.fill")
				}
			}
		}
		.displayName("smpl.time")
		.description("Displays the current date and time.")
	}
}

struct DateTimeControlIntent: AppIntent {
	static var title: LocalizedStringResource = "Show Date and Time"
	static var description = IntentDescription(
		"Displays the current date and time in Control Center.")

	func perform() async throws -> some IntentResult {
		.result(opensIntent: OpenURLIntent(URL(string: "smplwidgets://calendar")!))
	}
}
