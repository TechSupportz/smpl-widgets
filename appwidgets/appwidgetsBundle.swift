//
//  appwidgetsBundle.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

@main
struct AppWidgetsBundle: WidgetBundle {
    var body: some Widget {
		MinimalCalendarWidget()
		EventWidget()
        MonthCalendarWidget()
		WeatherWidget()
    }
}
