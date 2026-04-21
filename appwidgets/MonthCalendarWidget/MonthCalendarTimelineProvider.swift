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
#if DEBUG
        if SharedSettings.shared.isMockDataEnabled {
            var components = DateComponents()
            components.year = 2026
            components.month = 4
            components.day = 21
            let mockDate = Calendar.current.date(from: components) ?? currentDate
            completion(Timeline(entries: [MonthCalendarEntry(date: mockDate)], policy: .never))
            return
        }
#endif
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
