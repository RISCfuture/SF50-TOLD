# ``SF50_TOLD``

Takeoff and landing performance calculator for the Cirrus SF50 Vision Jet.

## Overview

SF50 TOLD is an iOS app that calculates takeoff and landing performance data
for the Cirrus SF50 Vision Jet. It generates Takeoff and Landing Reports (TLRs)
with runway analysis, performance calculations, and what-if scenarios.

The app integrates:
- Real-time weather from Aviation Weather (METAR/TAF) and Apple WeatherKit
- FAA NASR and OurAirports data for airport and runway information
- AFM-based performance calculations using both tabular and regression models
- NOTAM-based runway condition adjustments

## Architecture

The app follows a layered architecture:

1. **SF50 Shared**: Core framework with models, performance calculations, and weather loading
2. **TLR Module**: Report generation using Template Method pattern
3. **Loaders**: Airport data downloading and import
4. **Views**: SwiftUI interface (not documented)

## Topics

### Takeoff and Landing Reports

- <doc:TakeoffLandingReportGeneration>
- <doc:PerformanceScenarios>
- ``PerformanceInput``
- ``BaseReportData``
- ``TakeoffReportData``
- ``LandingReportData``
- ``BaseReportTemplate``
- ``TakeoffReportTemplate``
- ``LandingReportTemplate``
- ``PerformanceScenario``
- ``ScenarioFetcher``
- ``LimitingFactor``
- ``RunwayInfo``
- ``PerformanceDistance``
- ``TakeoffRunwayPerformance``
- ``LandingRunwayPerformance``
- ``ReportOutput``

### Airport Data Loading

- <doc:AirportDataLoading>
- ``AirportLoader``
- ``AirportLoaderViewModel``
