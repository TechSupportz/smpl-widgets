//
//  appwidgets.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
	func placeholder(in context: Context) -> DateEntry {
		DateEntry(date: Date())
	}

	func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
		-> DateEntry
	{
		DateEntry(date: Date())
	}

	func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
		DateEntry
	> {
		var entries: [DateEntry] = []

		// Generate a timeline consisting of five entries an hour apart, starting from the current date.
		let currentDate = Date()
		for hourOffset in 0..<5 {
			let entryDate = Calendar.current.date(
				byAdding: .hour,
				value: hourOffset,
				to: currentDate
			)!
			let entry = DateEntry(date: entryDate)
			entries.append(entry)
		}

		return Timeline(entries: entries, policy: .atEnd)
	}

	//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
	//        // Generate a list containing the contexts this widget is relevant in.
	//    }
}

struct DateEntry: TimelineEntry {
	let date: Date
}

struct calendarWidgetEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		VStack(spacing: 8) {
			HStack(spacing: 4) {
				Text("Fri")
					.font(.system(size: 24))
					.fontWidth(.condensed)
					.fontWeight(.bold)
					.foregroundStyle(.red)
					.padding(.vertical, -4)
				Text("Jul")
					.font(.system(size: 24))
					.fontWidth(.condensed)
					.fontWeight(.light)
					.padding(.vertical, -4)
			}
			Text("12")
				.font(.system(size: 128))
				.fontWidth(.compressed)
				.fontWeight(.bold)
				.monospacedDigit()
				.padding(.vertical, -30)
				.padding(.trailing, 12)
				.kerning(-8)
				.multilineTextAlignment(.center)

		}
	}
}

struct appwidgets: Widget {
	let kind: String = "appwidgets"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: ConfigurationAppIntent.self,
			provider: Provider()
		) { entry in
			calendarWidgetEntryView(entry: entry)
				.containerBackground(.fill.tertiary, for: .widget)

		}
	}
}

extension ConfigurationAppIntent {
	fileprivate static var smiley: ConfigurationAppIntent {
		let intent = ConfigurationAppIntent()
		intent.favoriteEmoji = "😀"
		return intent
	}

	fileprivate static var starEyes: ConfigurationAppIntent {
		let intent = ConfigurationAppIntent()
		intent.favoriteEmoji = "🤩"
		return intent
	}
}

#Preview(as: .systemSmall) {
	appwidgets()
} timeline: {
	DateEntry(date: .now)
}
