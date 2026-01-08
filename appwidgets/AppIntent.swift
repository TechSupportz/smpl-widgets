//
//  AppIntent.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource { "Configuration" }
	static var description: IntentDescription { "Configuration for the widget." }
}
