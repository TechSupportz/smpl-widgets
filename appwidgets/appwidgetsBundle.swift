//
//  appwidgetsBundle.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import WidgetKit
import SwiftUI

@main
struct AppWidgetsBundle: WidgetBundle {
    var body: some Widget {
		CalendarWidget()
		WeatherWidget()
    }
}
