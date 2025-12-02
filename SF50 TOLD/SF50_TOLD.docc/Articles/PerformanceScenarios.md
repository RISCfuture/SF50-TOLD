# Performance Scenarios

Creating what-if scenarios for alternative performance analysis.

## Overview

Performance scenarios enable pilots to see how performance changes under
different conditions. Common scenarios include hotter temperatures, reduced
headwind, heavier weights, or wet runways. The TLR displays performance
under each scenario alongside the forecast conditions.

## Scenario Architecture

![Scenario Architecture](scenario-architecture)

### Scenario Model

Users create and manage scenarios through the app UI. These are persisted
as `Scenario` SwiftData models with operation type (takeoff/landing).

### PerformanceScenario Struct

For calculations, ``ScenarioFetcher`` converts models to ``PerformanceScenario``
structs. These are `Sendable` and contain the delta adjustments to apply.

## Adjustment Types

Scenarios can adjust conditions in two ways:

### Delta Adjustments

Delta adjustments are added to the base conditions:

| Property | Example | Effect |
|----------|---------|--------|
| ``PerformanceScenario/deltaTemperature`` | +10°C | Hotter conditions |
| ``PerformanceScenario/deltaWindSpeed`` | -5 kt | Less headwind |
| ``PerformanceScenario/deltaWeight`` | +100 lb | Heavier aircraft |

### Overrides

Overrides replace base values entirely:

| Property | Example | Effect |
|----------|---------|--------|
| ``PerformanceScenario/flapSettingOverride`` | `.flaps100` | Different flap configuration |
| ``PerformanceScenario/contaminationOverride`` | `.wetSnow(depth:)` | Contaminated runway |
| ``PerformanceScenario/isDryOverride`` | `true` | Force dry runway (ignore NOTAM) |

## Applying Scenarios

The ``PerformanceScenario/apply(baseConditions:baseConfiguration:runway:)`` method returns
adjusted values for performance calculation:

```swift
let scenario = PerformanceScenario(
    deltaTemperature: .init(value: 10, unit: .celsius),
    deltaWindSpeed: .init(value: -5, unit: .knots),
    name: "Hot, Light Wind"
)

let (conditions, config, runway) = scenario.apply(
    baseConditions: forecastConditions,
    baseConfiguration: baseConfig,
    runway: runwayInput
)
```

### Wind Direction Handling

When delta wind speed causes a negative result (e.g., -5 kt applied to
3 kt headwind), the system:

1. Reverses wind direction (reciprocal)
2. Uses absolute value of speed

This converts a headwind to a tailwind correctly.

## Built-in Forecast Scenario

``ScenarioFetcher`` automatically prepends a "Forecast Conditions" scenario
with no adjustments. This ensures the TLR always shows performance under
actual forecast conditions first.

```swift
func fetchTakeoffScenarios() throws -> [PerformanceScenario] {
    let userScenarios = // ... fetch from SwiftData
    let forecastScenario = PerformanceScenario(name: "Forecast Conditions")
    return [forecastScenario] + userScenarios
}
```

## Common Scenario Patterns

### Conservative Weather

```swift
PerformanceScenario(
    deltaTemperature: .init(value: 5, unit: .celsius),
    deltaWindSpeed: .init(value: -5, unit: .knots),
    name: "+5°C, -5kt"
)
```

### Heavy Configuration

```swift
PerformanceScenario(
    deltaWeight: .init(value: 100, unit: .pounds),
    name: "+100 lb"
)
```

### Wet Runway (Override)

```swift
PerformanceScenario(
    contaminationOverride: .waterOrSlush(depth: .init(value: 0.125, unit: .inches)),
    name: "Wet Runway"
)
```

### Dry Runway (Clear NOTAM)

```swift
PerformanceScenario(
    isDryOverride: true,
    name: "Dry (Ignore NOTAM)"
)
```

## See Also

- ``PerformanceScenario``
- ``ScenarioFetcher``
