# Widget Architecture

Understanding the SF50 Runways widget's timeline-based data flow.

## Overview

The SF50 Runways widget uses WidgetKit's timeline architecture to display
up-to-date takeoff performance for all runways at the user's selected airport.
This article explains how data flows through the widget and how refreshes
are triggered.

## Timeline-Based Updates

WidgetKit widgets don't run continuously—they provide snapshots of data at
specific points in time. The system calls into the widget to generate a
timeline of entries, then displays those entries at the appropriate times.

![Widget Architecture](widget-architecture)

## Key Components

### TOLDProvider

``TOLDProvider`` implements `TimelineProvider` and is the entry point for
WidgetKit. It responds to three requests:

1. **Placeholder**: Returns an empty entry for the widget gallery preview
2. **Snapshot**: Returns current data for widget preview during configuration
3. **Timeline**: Returns entries with a refresh policy

```swift
func getTimeline(in context: Context,
                 completion: @escaping (Timeline<RunwayWidgetEntry>) -> Void) {
    Task { @MainActor in
        let entries = await performanceCalculator.generateEntries()
        completion(.init(
            entries: entries,
            policy: .after(Date().addingTimeInterval(900)) // 15 minutes
        ))
    }
}
```

### PerformanceCalculator

``PerformanceCalculator`` contains the core business logic. It:

1. Loads the selected airport from SwiftData (shared app group container)
2. Fetches current weather via `WeatherLoader` from SF50 Shared
3. Calculates takeoff distance for each runway using `DefaultPerformanceCalculationService` from SF50 Shared
4. Returns ``RunwayWidgetEntry`` instances for display

### RunwayWidgetEntry

``RunwayWidgetEntry`` is a `TimelineEntry` that captures a snapshot of:

- The airport name
- All runway snapshots (``RunwaySnapshot``)
- Weather conditions (`Conditions` from SF50 Shared)
- Calculated takeoff distances for each runway

### RunwaySnapshot

``RunwaySnapshot`` is a lightweight, `Sendable` copy of runway data suitable
for widget display. It captures the runway name, available distance, and
true heading without holding references to SwiftData objects.

## Data Sharing

The widget accesses the same data as the main app through:

1. **App Group Container**: SwiftData store at `group.codes.tim.TOLD`
2. **User Defaults**: Aircraft configuration via the Defaults library
3. **Shared Framework**: SF50 Shared provides weather loading and performance calculations

## Refresh Triggers

The widget refreshes in two scenarios:

### Scheduled Refresh

The timeline policy requests refresh every 15 minutes to capture weather
changes. This is appropriate for aviation weather which updates hourly
(METAR) or every 6 hours (TAF).

### Settings Change

When the user changes settings in the main app (airport, weight, fuel),
the app calls `WidgetCenter.shared.reloadTimelines(ofKind:)` to trigger
an immediate refresh.

## Empty States

The widget handles several empty states gracefully:

- **No airport selected**: Shows placeholder prompting user to select airport
- **Weather unavailable**: Shows airport and runways without performance values
- **Calculation error**: Shows "N/A" for affected runways

## See Also

- ``TOLDProvider``
- ``PerformanceCalculator``
- ``RunwayWidgetEntry``
- ``RunwaySnapshot``
