# ``SF50_RunwaysExtension``

Widget extension displaying takeoff performance for all runways at the selected airport.

## Overview

SF50 Runways is a WidgetKit extension that shows at-a-glance takeoff performance
data for the user's selected departure airport. It displays:

- Airport name and weather conditions
- All runways with wind components
- Calculated takeoff distances (or whether takeoff is possible)

The widget automatically refreshes every 15 minutes to capture weather changes
and uses the same performance calculation engine as the main app.

## Architecture

The widget follows a standard WidgetKit architecture:

1. **TOLDProvider**: Supplies timeline entries on demand
2. **PerformanceCalculator**: Loads data and performs calculations
3. **RunwayWidgetEntry**: Snapshot of data at a point in time
4. **SelectedAirportWidgetEntryView**: Renders the entry

## Topics

### Widget Architecture

- <doc:WidgetArchitecture>
- ``SelectedAirportPerformanceWidget``
- ``TOLDProvider``
- ``RunwayWidgetEntry``
- ``RunwaySnapshot``
- ``PerformanceCalculator``
