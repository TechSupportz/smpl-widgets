import SwiftUI
import WidgetKit

public struct MonthCalendarTimelineProvider: TimelineProvider {
	private let premiumPreviewDate: Date = {
		var components = DateComponents()
		components.year = 2026
		components.month = 4
		components.day = 21
		return Calendar.current.date(from: components) ?? .now
	}()

    public init() {}
    public func placeholder(in context: Context) -> MonthCalendarEntry {
		PremiumConfiguration.isUnlocked
			? MonthCalendarEntry(date: Date().startOfDay)
			: lockedPreviewEntry
	}

    public func getSnapshot(in context: Context, completion: @escaping @Sendable (MonthCalendarEntry) -> Void) {
		if !PremiumConfiguration.isUnlocked {
			completion(lockedPreviewEntry)
			return
		}

		completion(MonthCalendarEntry(date: Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<MonthCalendarEntry>) -> Void) {
		if !PremiumConfiguration.isUnlocked {
			completion(Timeline(entries: [lockedPreviewEntry], policy: .never))
			return
		}

		let currentDate = Date()
		let entries = [
			MonthCalendarEntry(date: currentDate.startOfDay),
			MonthCalendarEntry(date: currentDate.startOfNextDay)
		]
#if DEBUG
		if SharedSettings.shared.isMockDataEnabled {
			completion(Timeline(entries: [MonthCalendarEntry(date: premiumPreviewDate)], policy: .never))
			return
		}
#endif
		completion(Timeline(entries: entries, policy: .atEnd))
    }

	private var lockedPreviewEntry: MonthCalendarEntry {
		MonthCalendarEntry(date: premiumPreviewDate, isLocked: true)
	}
}
