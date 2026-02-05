import WidgetKit

public struct MonthCalendarEntry: TimelineEntry {
    public let date: Date
    public init(date: Date) { self.date = date }
}
