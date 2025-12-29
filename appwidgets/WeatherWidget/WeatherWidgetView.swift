//
//  WeatherWidgetView.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
	var entry: WeatherEntry
	
	var body: some View {
		VStack(spacing: 8) {
			Text("Weather ⛅")
		}
	}
}
