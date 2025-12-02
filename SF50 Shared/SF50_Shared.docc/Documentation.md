# ``SF50_Shared``

Shared framework providing models, performance calculations, and data loading for SF50 TOLD.

## Overview

SF50 Shared is the core framework used by the SF50 TOLD app and its widget extension.
It provides:

- **Domain Models**: Airport, runway, weather conditions, and aircraft configuration types
- **Performance Calculations**: Takeoff and landing performance computation using AFM data
- **Data Loading**: Weather (METAR/TAF), NOTAM, and location services
- **Persistence**: SwiftData models for airport and runway data

## Topics

### Airport and Runway Data

- <doc:DataLoadingPipeline>
- ``Airport``
- ``DataSource``
- ``Runway``

### Data Snapshots

Sendable value types for background calculations:

- ``AirportInput``
- ``RunwayInput``
- ``NOTAMInput``
- ``AirportDataCodable``

### Weather Integration

- <doc:WeatherAndConditions>
- ``Conditions``
- ``WeatherLoader``
- ``WeatherViewModel``

### NOTAM System

- ``NOTAM``
- ``Contamination``
- ``NOTAMLoader``
- ``NOTAMCache``
- ``NOTAMListResponse``
- ``NOTAMResponse``
- ``QLine``

### Performance Calculation

- <doc:PerformanceCalculationOverview>
- ``PerformanceCalculationService``
- ``DefaultPerformanceCalculationService``
- ``TakeoffResults``
- ``LandingResults``
- ``PerformanceModel``
- ``Value``

### Aircraft Configuration

- ``Configuration``
- ``FlapSetting``
- ``AircraftType``
- ``Limitations``
- ``LimitationsG1``
- ``LimitationsG2Plus``

### Scenarios

- ``Scenario``
- ``Operation``

### Location Services

- ``LocationStreamer``
- ``CoreLocationStreamer``
- ``LocationError``
- ``NearestAirportViewModel``

### Units and Measurements

Custom unit types for aviation-specific measurements:

- ``UnitDensity``
- ``UnitSlope``

### State Management

Types for managing asynchronous loading state:

- ``Loadable``
- ``ViewState``

### Error Handling

- ``IdentifiableError``
- ``WithIdentifiableError``
