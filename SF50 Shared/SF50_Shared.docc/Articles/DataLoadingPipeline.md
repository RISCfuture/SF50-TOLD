# Data Loading Pipeline

Loading airports, runways, and related data for performance calculations.

## Overview

SF50 TOLD loads airport and runway data from two sources: NASR (National Airspace System
Resources) and OurAirports. The loading pipeline manages data freshness, caching, and
provides reactive state updates.

## Airport Data Sources

Airport data originates from two complementary sources:

- **NASR**: Official FAA source with declared distances (TORA, TODA, LDA, etc.)
- **OurAirports**: Community-maintained with broader international coverage

The ``Airport/dataSource`` property indicates which source provided each airport.

## Loading with SwiftData

Airports and runways are persisted using SwiftData. The model context provides
direct access to stored data:

```swift
let descriptor = FetchDescriptor<Airport>(
    predicate: #Predicate { $0.ICAO_ID == "KSFO" }
)
let airports = try context.fetch(descriptor)
```

## Sendable Snapshots

For background performance calculations, domain models are converted to
`Sendable` snapshots that can cross actor boundaries:

- ``AirportInput`` - Immutable airport data
- ``RunwayInput`` - Immutable runway data with NOTAM adjustments
- ``NOTAMInput`` - Immutable NOTAM state

```swift
// Create snapshots for background calculation
let airportInput = AirportInput(from: airport)
let runwayInput = RunwayInput(from: runway, airport: airport)
let notamInput = runway.notam.map { NOTAMInput(from: $0) }

// Pass to performance model (actor-safe)
let model = RegressionPerformanceModelG1(
    conditions: conditions,
    configuration: configuration,
    runway: runwayInput,
    notam: notamInput
)
```

## Location-Based Discovery

The ``LocationStreamer`` protocol provides device location for finding nearby
airports. ``CoreLocationStreamer`` is the production implementation:

```swift
@Environment(\.locationStreamer) var locationStreamer

// Start streaming location updates
for await location in locationStreamer.locationUpdates() {
    // Find airports near this location
}
```

## NOTAM Loading

NOTAMs are loaded from a custom API service. The loading and caching flow:

1. Check ``NOTAMCache`` for cached results
2. If cache miss, fetch from ``NOTAMLoader``
3. Cache successful responses
4. Filter by effective dates

```swift
// Check cache first
if let cached = await NOTAMCache.shared.get(for: "KJFK") {
    return cached
}

// Fetch from API
let response = try await NOTAMLoader.shared.fetchNOTAMs(
    for: "KJFK",
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400 * 7)
)

// Cache results
await NOTAMCache.shared.set(response.data, for: "KJFK")
```

## Loading States

Both ``Loadable`` and ``ViewState`` track async loading states:

```swift
var airports: Loadable<[Airport]> = .notLoaded

func load() async {
    airports = .loading
    do {
        let data = try await fetchAirports()
        airports = .value(data)
    } catch {
        airports = .error(error)
    }
}
```

## See Also

- ``Airport``
- ``Runway``
- ``AirportInput``
- ``RunwayInput``
- ``NOTAMInput``
- ``NOTAMLoader``
- ``NOTAMCache``
- ``LocationStreamer``
- ``Loadable``
