# Weather and Conditions

Working with weather data and atmospheric conditions.

## Overview

SF50 TOLD uses weather data from multiple sources to populate ``Conditions`` objects
for performance calculations. The framework provides loaders for fetching weather
from the National Weather Service and Apple WeatherKit.

## Weather Sources

The ``Conditions/Source`` enum identifies where weather data originated:

- **NWS**: METAR observations and TAF forecasts from the National Weather Service
- **WeatherKit**: Current and forecast weather from Apple WeatherKit
- **augmented**: NWS data supplemented with WeatherKit for missing values
- **ISA**: International Standard Atmosphere (used when no weather is available)
- **entered**: User-entered manual weather data

## Loading Weather

Use ``WeatherLoader`` to fetch weather data:

```swift
let loader = WeatherLoader()

// Load METAR and TAF
let (metar, taf) = try await loader.loadWeather(
    for: airport.coordinate,
    icaoID: airport.ICAO_ID
)

// Create conditions from METAR
if let metar {
    let conditions = Conditions(observation: metar)
}

// Or from TAF forecast
if let taf {
    let conditions = Conditions(forecast: taf)
}
```

## The Conditions Type

``Conditions`` encapsulates all weather data needed for performance calculations:

- **Wind**: ``Conditions/windDirection`` and ``Conditions/windSpeed``
- **Temperature**: ``Conditions/temperature`` and ``Conditions/dewpoint``
- **Pressure**: ``Conditions/seaLevelPressure``
- **Validity**: ``Conditions/validTime`` indicates when the weather is applicable

### Combining Conditions

When weather data is incomplete, conditions can be combined:

```swift
// Start with METAR conditions
var conditions = Conditions(observation: metar)

// Fill in missing values from WeatherKit
conditions = conditions.adding(weather: currentWeather)
```

### Derived Values

Conditions provides computed values for performance calculations:

- ``Conditions/temperature(at:)`` - Temperature adjusted for elevation
- ``Conditions/densityAltitude(elevation:)`` - Density altitude calculation
- ``Conditions/windsCalm`` - True if wind speed is less than 1 knot

## See Also

- ``Conditions``
- ``WeatherLoader``
