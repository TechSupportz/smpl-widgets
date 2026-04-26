import WidgetKit

public struct MonthCalendarEntry: TimelineEntry {
    public let date: Date
	public let isLocked: Bool

	public init(date: Date, isLocked: Bool = false) {
		self.date = date
		self.isLocked = isLocked
	}
}
