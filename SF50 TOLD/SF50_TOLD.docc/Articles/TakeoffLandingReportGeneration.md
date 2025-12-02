# Takeoff and Landing Report Generation

Understanding the TLR generation pipeline and Template Method pattern.

## Overview

The Takeoff and Landing Report (TLR) system generates comprehensive HTML reports
showing performance data for all runways at an airport under various conditions.
The system uses the Template Method design pattern to share common logic while
allowing takeoff and landing-specific customizations.

## Pipeline Architecture

TLR generation follows a two-phase pipeline:

![TLR Pipeline](tlr-pipeline)

### Phase 1: Data Generation

``BaseReportData`` and its subclasses calculate:

1. **Runway Analysis**: Maximum weight for each runway with limiting factor
2. **Scenario Performance**: Performance under each what-if scenario

The ``BaseReportData/generate()`` method returns a ``ReportOutput`` containing both.

### Phase 2: HTML Rendering

``BaseReportTemplate`` and its subclasses render the data to HTML:

1. **Header**: Airport, date, aircraft, weather source
2. **Data Table**: Planned conditions summary
3. **Runways Table**: Max weights and limiting factors
4. **Performance Tables**: One per scenario (accordion for non-forecast)

## Template Method Pattern

Both data generation and rendering use the Template Method pattern, where
the base class defines the algorithm skeleton and subclasses provide
specific implementations.

### BaseReportData Template Methods

```swift
class BaseReportData<PerformanceType, ScenarioType> {
    // Algorithm skeleton
    func generate() throws -> ReportOutput<ScenarioType> {
        let runways = try generateRunwayInfo()
        let scenarios = try generateScenarios()
        return .init(runwayInfo: runways, scenarios: scenarios)
    }

    // Template methods (overridden by subclasses)
    func operation() -> Operation { fatalError() }
    func maxWeight() -> Measurement<UnitMass> { fatalError() }
    func calculatePerformance(for:conditions:config:) throws -> PerformanceType { fatalError() }
    func determineMaxWeight(runway:) throws -> (Measurement<UnitMass>, LimitingFactor) { fatalError() }
    func createScenario(name:runways:) -> ScenarioType { fatalError() }
}
```

### Takeoff vs Landing Implementations

| Aspect | TakeoffReportData | LandingReportData |
|--------|-------------------|-------------------|
| Max Weight | `maxTakeoffWeight` | `maxLandingWeight` |
| Performance | Ground run, total distance, climb | Vref, landing run/distance, go-around |
| Constraints | AFM, field, obstacle | AFM, field, climb gradient |

## Max Weight Determination

Both subclasses use binary search to find the maximum weight that satisfies
all constraints. The search increments by 50 pounds and checks:

1. AFM chart limits (offscale high/low)
2. Available runway length
3. Operation-specific constraints (obstacle clearance or go-around)

```swift
func binarySearchMaxWeight(
    runway: RunwayInput,
    min: Measurement<UnitMass>,
    max: Measurement<UnitMass>,
    isValid: (Measurement<UnitMass>) throws -> (valid: Bool, factor: LimitingFactor)
) rethrows -> (weight: Measurement<UnitMass>, limitingFactor: LimitingFactor?)
```

## Usage Example

```swift
// Create input from user configuration
let input = PerformanceInput(
    airport: airportInput,
    runway: runwayInput,
    conditions: conditions,
    weight: takeoffWeight,
    flapSetting: .flaps50,
    safetyFactor: 1.0,
    useRegressionModel: true,
    updatedThrustSchedule: true,
    emptyWeight: emptyWeight,
    date: Date()
)

// Fetch user-defined scenarios
let fetcher = ScenarioFetcher(modelContainer: container)
let scenarios = try await fetcher.fetchTakeoffScenarios()

// Generate report
let html = try generateTakeoffReport(input: input, scenarios: scenarios)
```

## See Also

- ``PerformanceInput``
- ``BaseReportData``
- ``TakeoffReportData``
- ``LandingReportData``
- ``BaseReportTemplate``
- ``generateTakeoffReport(input:scenarios:)``
- ``generateLandingReport(input:scenarios:)``
