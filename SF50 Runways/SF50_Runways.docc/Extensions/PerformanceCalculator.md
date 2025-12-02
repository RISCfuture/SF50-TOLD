# ``SF50_RunwaysExtension/PerformanceCalculator``

## Overview

``PerformanceCalculator`` is the core business logic component of the
SF50 Runways widget. It bridges the gap between WidgetKit's timeline
system and the app's performance calculation engine.

## Data Flow

When ``TOLDProvider`` requests timeline entries, the calculator:

1. **Loads the selected airport** from the shared SwiftData container
2. **Fetches current weather** via `WeatherLoader` from SF50 Shared
3. **Creates runway snapshots** for safe cross-actor transfer
4. **Calculates takeoff distance** for each runway using the shared
   `DefaultPerformanceCalculationService` from SF50 Shared
5. **Returns timeline entries** containing all performance data

## Configuration

The calculator reads aircraft configuration from user defaults:

| Setting | Source |
|---------|--------|
| Empty weight | `Defaults[.emptyWeight]` |
| Payload | `Defaults[.payload]` |
| Fuel quantity | `Defaults[.takeoffFuel]` |
| Fuel density | `Defaults[.fuelDensity]` |
| Safety factors | `Defaults[.safetyFactorDry/Wet]` |
| Thrust schedule | `Defaults[.updatedThrustSchedule]` |
| Regression model | `Defaults[.useRegressionModel]` |

## Error Handling

The calculator handles missing data gracefully:

- **No airport selected**: Returns empty entry
- **Weather unavailable**: Returns entry with airport/runways but nil conditions
- **Calculation error**: Marks individual runway as `.invalid`

## Topics

### Generating Entries

- ``generateEntries()``
