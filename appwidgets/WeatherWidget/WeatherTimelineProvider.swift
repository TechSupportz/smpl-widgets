//
//  WeatherTimelineProvider.swift
//  appwidgets
//
//  Created by Nitish on 11/11/25.
//

import CoreLocation
import SwiftUI
import WeatherKit
import WidgetKit
import os

struct WeatherTimelineProvider: TimelineProvider {
	let logger = Logger(subsystem: "com.yourname.yourapp", category: "WeatherWidget")
	private let dummyWeatherEntry = WeatherEntry(
		date: Date(),
		condition: "cloudy",
		temperature: Measurement<UnitTemperature>(value: 25.0, unit: .celsius,),
		symbol: "cloud.sun.fill"
	)

	func placeholder(in context: Context) -> WeatherEntry {
		dummyWeatherEntry
	}

	func getSnapshot(in context: Context, completion: @escaping @Sendable (WeatherEntry) -> Void) {
		completion(dummyWeatherEntry)
	}

	func getTimeline(
		in context: Context,
		completion: @escaping @Sendable (Timeline<WeatherEntry>) -> Void
	) {
		print(">>> HELLO???")
		Task {
			print("Runnning Task")
			let currentDate = Date()
			let nextUpdate = Calendar.current.date(byAdding: .minute, value: 60, to: currentDate)!

			let weatherService = WeatherService()
			let locationFetcher = await LocationFetcher()

			do {
				let userLocation = try await locationFetcher.getLocation()
				print(userLocation)
				let weather = try await weatherService.weather(for: userLocation)

				logger.info("✅ Weather fetched successfully.")

				let entry = WeatherEntry(
					date: currentDate,
					condition: weather.currentWeather.condition.description,
					temperature: weather.currentWeather.apparentTemperature,
					symbol: "\(weather.currentWeather.symbolName).fill"
				)

				completion(Timeline(entries: [entry], policy: .after(nextUpdate)))

			} catch {
				logger.error("❌ Failed to fetch weather: \(error.localizedDescription)")
				let errorUpdateDate = Calendar.current.date(
					byAdding: .second,
					value: 10, to: currentDate
				)!

				let errorEntry = WeatherEntry(
					date: currentDate,
					condition: "error",
					temperature: Measurement<UnitTemperature>(value: 0.0, unit: .celsius),
					symbol: "questionmark.square.dashed"
				)
				completion(Timeline(entries: [errorEntry], policy: .after(errorUpdateDate)))
			}
		}

	}

}
