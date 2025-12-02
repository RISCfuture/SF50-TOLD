# Performance Calculation Overview

Understanding how SF50 TOLD calculates aircraft performance.

## Overview

SF50 TOLD calculates takeoff and landing performance using data from the SF50 Vision Jet
Aircraft Flight Manual (AFM). The calculation pipeline transforms atmospheric conditions,
aircraft configuration, and runway data into specific performance values like distances,
speeds, and climb rates.

## The Calculation Pipeline

Performance calculations flow through several stages:

1. **Input Collection**: Gather ``Conditions``, ``Configuration``, and ``RunwayInput``
2. **Model Selection**: Choose the appropriate ``PerformanceModel`` implementation
3. **Calculation**: Compute performance values using AFM data
4. **Results**: Return ``TakeoffResults`` or ``LandingResults``

## Performance Models

The framework provides multiple ``PerformanceModel`` implementations:

- **Tabular Models**: Direct interpolation from AFM tables
  - `TabularPerformanceModelG1` for G1 aircraft
  - `TabularPerformanceModelG2Plus` for G2/G2+ aircraft

- **Regression Models**: Curve-fitted equations for smoother results
  - `RegressionPerformanceModelG1` for G1 aircraft
  - `RegressionPerformanceModelG2Plus` for G2/G2+ aircraft

## Using the Service

The ``DefaultPerformanceCalculationService`` singleton provides the primary API:

```swift
let service = DefaultPerformanceCalculationService.shared

// Create a performance model
let model = service.createPerformanceModel(
    conditions: conditions,
    configuration: configuration,
    runway: runway,
    notam: notam,
    useRegressionModel: true,
    updatedThrustSchedule: isG2Plus
)

// Calculate performance
let takeoffResults = try service.calculateTakeoff(for: model, safetyFactor: 1.0)
let landingResults = try service.calculateLanding(for: model, safetyFactor: 1.0)
```

## Handling Uncertainty

Performance values are wrapped in ``Value`` to represent:

- **Definite values**: ``Value/value(_:)`` for exact results
- **Values with uncertainty**: ``Value/valueWithUncertainty(_:uncertainty:)`` for results
  with statistical confidence intervals
- **Error states**: ``Value/invalid``, ``Value/offscaleHigh``, ``Value/offscaleLow``, etc.

This design allows the UI to display appropriate warnings when calculations are
outside the valid AFM data range.

## See Also

- ``PerformanceCalculationService``
- ``PerformanceModel``
- ``TakeoffResults``
- ``LandingResults``
- ``Value``
