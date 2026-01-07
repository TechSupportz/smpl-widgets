# AGENTS.md - smpl-widgets

This document provides guidance for AI coding agents working in this iOS WidgetKit codebase.

## Project Overview

An iOS app providing home screen widgets built with SwiftUI and WidgetKit.

**Targets:**
- `smpl-widgets` - Main iOS app (container for widgets)
- `appwidgetsExtension` - WidgetKit extension containing all widgets

**Current Widgets:**
- CalendarWidget - Displays current day, month, and date
- WeatherWidget - Work in progress (has syntax errors)

## Build Commands

### Build via Xcode CLI

```bash
# Build the main app (Debug)
xcodebuild -project smpl-widgets.xcodeproj -scheme "smpl widgets" -configuration Debug build

# Build for iOS Simulator
xcodebuild -project smpl-widgets.xcodeproj -scheme "smpl widgets" \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build Release
xcodebuild -project smpl-widgets.xcodeproj -scheme "smpl widgets" -configuration Release build

# Clean build folder
xcodebuild -project smpl-widgets.xcodeproj -scheme "smpl widgets" clean
```

### Build Widget Extension

```bash
xcodebuild -project smpl-widgets.xcodeproj -scheme "appwidgetsExtension" build
```

## Testing

**Note:** This project currently has no test targets configured.

When tests are added:

```bash
# Run all tests
xcodebuild test -project smpl-widgets.xcodeproj -scheme "smpl widgets" \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test file
xcodebuild test -project smpl-widgets.xcodeproj -scheme "smpl widgets" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:"smpl widgetsTests/CalendarWidgetTests"

# Run a single test method
xcodebuild test -project smpl-widgets.xcodeproj -scheme "smpl widgets" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:"smpl widgetsTests/CalendarWidgetTests/testTimelineGeneration"
```

## Linting

No SwiftLint configuration exists. If added, run:

```bash
swiftlint lint
swiftlint lint --fix  # Auto-fix issues
```

## Project Structure

```
smpl-widgets/
├── appwidgets/                      # WidgetKit Extension
│   ├── CalendarWidget/              # Calendar widget module
│   │   ├── CalendarEntry.swift      # TimelineEntry data model
│   │   ├── CalendarTimelineProvider.swift  # Timeline data provider
│   │   ├── CalendarWidget.swift     # Widget configuration
│   │   └── CalendarWidgetView.swift # SwiftUI view
│   ├── WeatherWidget/               # Weather widget (WIP)
│   ├── Common/                      # Shared utilities and extensions
│   │   └── Extensions.swift         # Common extensions (Date, View, etc.)
│   ├── AppIntent.swift              # App Intents for widget configuration
│   ├── AppWidgetsBundle.swift       # Widget bundle entry point
│   └── Info.plist
├── smpl-widgets/                    # Main iOS App
│   ├── AppIcon.icon/                # App icon assets
│   ├── Assets.xcassets/             # Asset catalog
│   ├── ContentView.swift            # Main app view
│   └── smpl_widgetsApp.swift        # App entry point
├── smpl-widgets.xcodeproj/          # Xcode project
└── smpl-widgets.entitlements        # App capabilities (WeatherKit)
```

## Code Style Guidelines

### File Header

All files use standard Xcode header format:
```swift
//
//  FileName.swift
//  TargetName
//
//  Created by Author on MM/DD/YY.
//
```

### Imports

- Import only required frameworks
- Order: SwiftUI first, then WidgetKit, then others
- One import per line

```swift
import SwiftUI
import WidgetKit
import AppIntents
```

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Structs/Classes | PascalCase | `CalendarWidget`, `CalendarEntry` |
| Properties | camelCase | `isRedirecting`, `startOfNextDay` |
| Functions | camelCase | `getTimeline`, `placeholder` |
| Constants | camelCase | `let kind: String` |

### Widget Module Pattern

Each widget follows a 4-file pattern:
1. `*Entry.swift` - TimelineEntry conforming struct
2. `*TimelineProvider.swift` - TimelineProvider implementation
3. `*Widget.swift` - Widget definition
4. `*WidgetView.swift` - SwiftUI view

### Indentation

- Use **tabs** for indentation (project default)
- Some files mix tabs/spaces - prefer tabs for consistency

### SwiftUI View Style

```swift
struct ExampleWidgetView: View {
    var entry: ExampleEntry

    var body: some View {
        VStack(spacing: 8) {
            Text("Content")
                .font(.system(size: 24))
                .fontWeight(.bold)
        }
    }
}
```

### Widget Configuration Pattern

```swift
struct ExampleWidget: Widget {
    let kind: String = "ExampleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ExampleTimelineProvider()
        ) { entry in
            ExampleWidgetView(entry: entry)
                .containerBackground(.white, for: .widget)
                .environment(\.colorScheme, .light)
        }
        .configurationDisplayName("Display Name")
        .description("Widget description.")
        .supportedFamilies([.systemSmall])
    }
}
```

### Timeline Provider Pattern

```swift
struct ExampleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExampleEntry {
        ExampleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ExampleEntry) -> Void) {
        completion(ExampleEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<ExampleEntry>) -> Void
    ) {
        // Generate timeline entries
        let entries = [ExampleEntry(date: .now)]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
```

### Preview Macros

Use `#Preview` macro for widget previews:
```swift
#Preview(as: .systemSmall) {
    CalendarWidget()
} timeline: {
    CalendarEntry(date: .now)
}
```

For regular views:
```swift
#Preview {
    ContentView()
}
```

### Error Handling

- Use force unwrapping sparingly (e.g., `Calendar.current.date(byAdding:)!`)
- Prefer guard statements for early returns
- Handle URL schemes with conditional checks

### Concurrency

Project uses modern Swift concurrency settings:
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- Use `@Sendable` for closures in timeline providers

## Known Issues

1. **WeatherWidget has syntax errors** - WeatherEntry.swift and WeatherWidgetView.swift have incomplete code
2. **Debug print statements** - CalendarTimelineProvider.swift contains `print()` calls that should be removed for production

## Dependencies

- No external dependencies (SPM, CocoaPods, Carthage)
- Uses only Apple frameworks: SwiftUI, WidgetKit, AppIntents, UIKit

## Entitlements

- WeatherKit capability enabled for weather widget functionality
