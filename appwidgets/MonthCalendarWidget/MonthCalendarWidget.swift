//
//  CalendarWidget.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct MonthCalendarWidget: Widget {
    let kind: String = "MonthCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MonthCalendarTimelineProvider()
        ) { (entry: MonthCalendarEntry) in
            MonthCalendarWidgetView(entry: entry)
                .alwaysWhiteWidgetStyle()
        }
        .configurationDisplayName("smpl.month.calendar")
        .description("A simple widget which displays a calendar of the current month")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    MonthCalendarWidget()
} timeline: {
    MonthCalendarEntry(date: Calendar.current.date(byAdding: .month, value: -1, to: .now)!)
    MonthCalendarEntry(date: .now)
    MonthCalendarEntry(date: Calendar.current.date(byAdding: .month, value: 1, to: .now)!)
}
