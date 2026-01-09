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
	let logger = Logger(subsystem: "com.tnitish.smpl-widgets", category: "WeatherWidget")
	private let calendar = Calendar.current

	/// Fixed fetch hours: 6am, 10am, 2pm, 6pm, 10pm
	private let fetchHours = [6, 10, 14, 18, 22]

	private let dummyWeatherEntry = WeatherEntry(
		date: Date(),
		condition: "cloudy",
		temperature: Measurement<UnitTemperature>(value: 25.0, unit: .celsius),
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
		Task {
			let currentDate = Date()
			let weatherService = WeatherService()

			do {
				let userLocation = try await LocationFetcher.shared.getLocation()
				logger.info(
					"📍 Location fetched: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)"
				)

				let weather = try await weatherService.weather(for: userLocation)
				logger.info("✅ Weather hourly forecast fetched successfully.")

				let entries = generateTimelineEntries(
					from: weather.hourlyForecast,
					currentDate: currentDate
				)

				let nextFetchTime = calculateNextFetchTime(from: currentDate)
				logger.info("📅 Next fetch scheduled for: \(nextFetchTime)")

				completion(Timeline(entries: entries, policy: .after(nextFetchTime)))
			} catch {
				logger.error("❌ Failed to fetch weather: \(error.localizedDescription)")
				let errorUpdateDate = calendar.date(
					byAdding: .minute,
					value: 30,
					to: currentDate
				)!

				var errorCondition = "error"

				if error.localizedDescription.contains("kCLErrorDomain") {
					errorCondition += ",location"
				}

				let errorEntry = WeatherEntry(
					date: currentDate,
					condition: errorCondition,
					temperature: Measurement<UnitTemperature>(value: 0.0, unit: .celsius),
					symbol: "questionmark.square.dashed"
				)
				completion(Timeline(entries: [errorEntry], policy: .after(errorUpdateDate)))
			}
		}
	}

	/// Calculates the next scheduled fetch time based on the fixed schedule.
	/// Fetch hours: 6am, 10am, 2pm, 6pm, 10pm
	private func calculateNextFetchTime(from date: Date) -> Date {
		let currentHour = calendar.component(.hour, from: date)

		// Find the next fetch hour after the current hour
		if let nextHour = fetchHours.first(where: { $0 > currentHour }) {
			return calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: date)!
		} else {
			// Next fetch is 6am tomorrow
			let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
			return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: tomorrow)!
		}
	}

	/// Calculates the number of hours from the current time until the next fetch time.
	/// Used to determine how many timeline entries to generate.
	private func calculateHoursUntilNextFetch(from date: Date) -> Int {
		let nextFetch = calculateNextFetchTime(from: date)
		let hourDifference = calendar.dateComponents([.hour], from: date, to: nextFetch).hour ?? 4
		// Add 1 because we want to include the hour at nextFetch time
		// e.g., 7am to 10am should give us entries for 7, 8, 9, 10 = 4 entries
		return max(hourDifference + 1, 1)
	}

	/// Generates timeline entries from hourly forecast data.
	/// Each entry is set to display at XX:45 for the following hour's forecast.
	/// e.g., at 6:45am the widget shows 7am forecast, at 7:45am shows 8am forecast.
	private func generateTimelineEntries(
		from forecast: Forecast<HourWeather>,
		currentDate: Date
	) -> [WeatherEntry] {
		let hoursToGenerate = calculateHoursUntilNextFetch(from: currentDate)
		logger.info("📊 Generating \(hoursToGenerate) timeline entries")

		var entries: [WeatherEntry] = []

		// Get the current hour's start time (e.g., 7:28am -> 7:00am)
		let currentHourStart = calendar.date(
			from: calendar.dateComponents([.year, .month, .day, .hour], from: currentDate)
		)!

		// Create an entry for the current partial hour first (displays immediately)
		// This uses the current hour's forecast
		if let currentHourWeather = forecast.first(where: {
			calendar.isDate($0.date, equalTo: currentHourStart, toGranularity: .hour)
		}) {
			let immediateEntry = WeatherEntry(
				date: currentDate,
				condition: currentHourWeather.condition.description,
				temperature: currentHourWeather.apparentTemperature,
				symbol: "\(currentHourWeather.symbolName).fill"
			)
			entries.append(immediateEntry)
		}

		// Generate entries for upcoming hours
		// Each entry displays at XX:45 for the next hour's forecast
		for hourOffset in 0..<hoursToGenerate {
			// The hour we want to show the forecast for
			guard
				let forecastHour = calendar.date(
					byAdding: .hour,
					value: hourOffset + 1,
					to: currentHourStart
				)
			else { continue }

			// Find the forecast for this hour
			guard
				let hourWeather = forecast.first(where: {
					calendar.isDate($0.date, equalTo: forecastHour, toGranularity: .hour)
				})
			else { continue }

			// The entry should display at 45 minutes of the previous hour
			// e.g., 7am forecast displays at 6:45am
			let displayTime = calendar.date(
				byAdding: .minute,
				value: -15,
				to: forecastHour
			)!

			// Only add if display time is in the future
			if displayTime > currentDate {
				let entry = WeatherEntry(
					date: displayTime,
					condition: hourWeather.condition.description,
					temperature: hourWeather.apparentTemperature,
					symbol: "\(hourWeather.symbolName).fill"
				)
				entries.append(entry)
				logger.debug(
					"📝 Entry: \(displayTime) -> \(hourWeather.condition.description) \(hourWeather.apparentTemperature)"
				)
			}
		}

		// Fallback: ensure we always have at least one entry
		if entries.isEmpty {
			entries.append(WeatherEntry(
				date: currentDate,
				condition: "error",
				temperature: Measurement<UnitTemperature>(value: 0.0, unit: .celsius),
				symbol: "questionmark.square.dashed"
			))
		}

		return entries
	}
}
