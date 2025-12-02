# ``SF50_TOLD/PerformanceScenario``

## Overview

``PerformanceScenario`` defines adjustments for what-if performance analysis.
Each scenario can modify temperature, wind, weight, flaps, or runway condition
to see how performance changes under different circumstances.

## Creating Scenarios

### From Defaults

Create a scenario with no adjustments (used for "Forecast Conditions"):

```swift
let baseline = PerformanceScenario(name: "Forecast Conditions")
```

### With Delta Adjustments

Create a scenario with delta values that add to base conditions:

```swift
let hotDay = PerformanceScenario(
    deltaTemperature: .init(value: 10, unit: .celsius),
    name: "Hot Day (+10°C)"
)
```

### With Overrides

Create a scenario that replaces values entirely:

```swift
let wetRunway = PerformanceScenario(
    contaminationOverride: .waterOrSlush(depth: .init(value: 0.125, unit: .inches)),
    name: "Wet Runway"
)
```

## Applying Scenarios

Use ``apply(baseConditions:baseConfiguration:runway:)`` to get adjusted values:

```swift
let (adjustedConditions, adjustedConfig, adjustedRunway) = scenario.apply(
    baseConditions: forecast,
    baseConfiguration: config,
    runway: runwayInput
)
```

## Topics

### Delta Adjustments

- ``deltaTemperature``
- ``deltaWindSpeed``
- ``deltaWeight``

### Overrides

- ``flapSettingOverride``
- ``contaminationOverride``
- ``isDryOverride``

### Applying

- ``apply(baseConditions:baseConfiguration:runway:)``

### Conversion

- ``from(_:)``
