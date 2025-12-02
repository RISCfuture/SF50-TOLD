# ``SF50_RunwaysExtension/RunwaySnapshot``

## Overview

``RunwaySnapshot`` provides a thread-safe representation of runway data
for widget display. Unlike the SwiftData `Runway` model from SF50 Shared, snapshots can
be safely passed across actor boundaries and stored in timeline entries.

Each snapshot captures the essential information needed to display runway
performance:
- The runway name (e.g., "09", "27L")
- Available takeoff distance
- True heading for wind calculations

## Creating Snapshots

Snapshots are typically created by ``PerformanceCalculator`` when generating
timeline entries:

```swift
let snapshots = airport.runways.map { runway in
    RunwaySnapshot(
        name: runway.name,
        takeoffDistanceOrLength: runway.takeoffDistanceOrLength,
        trueHeading: runway.trueHeading
    )
}
```

## Sorting

Use ``NameComparator`` to sort runways in a natural order that groups
reciprocal runways together (09/27 before 18/36).

## Topics

### Creating Snapshots

- ``init(name:takeoffDistanceOrLength:trueHeading:)``

### Properties

- ``name``
- ``takeoffDistanceOrLength``
- ``trueHeading``

### Sorting

- ``NameComparator``
