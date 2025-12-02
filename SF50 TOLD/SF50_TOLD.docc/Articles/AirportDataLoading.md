# Airport Data Loading

Downloading and importing airport data from GitHub.

## Overview

SF50 TOLD requires airport and runway data to calculate performance. This data
is pre-processed from FAA NASR and OurAirports sources, compressed, and hosted
on GitHub. The ``AirportLoader`` actor downloads and imports this data into
SwiftData on first launch and when updates are available.

## Data Pipeline

![Airport Loading Pipeline](airport-loading-pipeline)

## Update Decision Logic

``AirportLoaderViewModel`` determines when to show the loading UI based on:

### Required Load (Cannot Skip)

- No airports in database (`noData`)
- Schema version mismatch (app update changed data format)

### Optional Load (Can Defer)

- AIRAC cycle expired but data exists
- User can tap "Load Later" to defer

### Current Data

- Schema matches and cycle is effective
- No loader UI shown

```swift
var showLoader: Bool {
    (noData || needsLoad) && !deferred
}
```

## AIRAC Cycles

Airport data is organized by AIRAC (Aeronautical Information Regulation And
Control) cycles—28-day periods used in aviation. The app checks if the loaded
cycle is still effective:

```swift
private func outOfDate(cycle: Cycle?) -> Bool {
    if let cycle, cycle.isEffective { return false }
    return true
}
```

New cycle data is typically uploaded to GitHub a few days before the cycle
becomes effective. If data isn't available yet, ``AirportLoader`` throws
``AirportLoader/Errors/cycleNotAvailable``.

## Loading Progress

The loader reports progress through the ``AirportLoader/State`` enum:

| State | Description |
|-------|-------------|
| `.idle` | Not started |
| `.downloading(progress:)` | Downloading from GitHub (0.0-1.0) |
| `.extracting(progress:)` | Decompressing LZMA |
| `.loading(progress:)` | Importing to SwiftData (0.0-1.0) |
| `.finished` | Complete |

The view model polls the loader state every 250ms to update the UI:

```swift
Task { [weak self] in
    while !Task.isCancelled {
        let state = await loader.state
        self?.state = state
        try? await Task.sleep(for: .seconds(0.25))
    }
}
```

## Batch Import

To avoid blocking the main actor, airport import uses batch processing:

1. Airports are processed in batches of 100
2. Each batch runs concurrently using `withThrowingDiscardingTaskGroup`
3. SwiftData is saved after each batch
4. `Task.yield()` allows UI updates between batches

```swift
for (batchIndex, batch) in batches.enumerated() {
    try await withThrowingDiscardingTaskGroup { group in
        for airport in batch {
            group.addTask { await self.addAirport(airport) }
        }
    }
    try modelContext.save()
    state = .loading(progress: Float(completed) / Float(total))
    await Task.yield()
}
```

## Data Sources

The compressed data combines two sources:

### FAA NASR

National Airspace System Resources provides authoritative data for US airports:
- Precise runway lengths and distances
- Displaced thresholds
- Gradient information
- Official identifiers

### OurAirports

Community-maintained database supplements NASR with:
- International airports
- Time zone information
- Additional airports not in NASR

## See Also

- ``AirportLoader``
- ``AirportLoaderViewModel``
