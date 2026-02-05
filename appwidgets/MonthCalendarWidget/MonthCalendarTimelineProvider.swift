import SwiftUI
import WidgetKit

public struct MonthCalendarTimelineProvider: TimelineProvider {
    public init() {}
    public func placeholder(in context: Context) -> MonthCalendarEntry { MonthCalendarEntry(date: Date()) }
    public func getSnapshot(in context: Context, completion: @escaping @Sendable (MonthCalendarEntry) -> Void) {
        completion(MonthCalendarEntry(date: Date()))
    }
    public func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<MonthCalendarEntry>) -> Void) {
        let currentDate = Date()
        let entries = [
            MonthCalendarEntry(date: currentDate.startOfDay),
            MonthCalendarEntry(date: currentDate.startOfNextDay)
        ]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
