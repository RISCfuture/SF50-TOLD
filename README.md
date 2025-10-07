# SF50 TOLD

A comprehensive Takeoff and Landing Data (TOLD) calculator for the Cirrus SF50 Vision Jet, supporting G1 through G2+ models.

## ⚠️ Disclaimer

This app has not been approved by the FAA or by Cirrus Aircraft as an official source of performance information. Always verify performance information with official sources when using this app.

## Features

### Performance Calculations

- **Takeoff Performance**: Calculate ground run, takeoff distance over 50ft obstacle, and Vx climb gradient
- **Landing Performance**: Calculate landing distance, ground run, VREF, and go-around climb gradient
- **Multi-Model Support**: G1, G2, and G2+ (with updated thrust schedule) models
- **Safety Factors**: Configurable safety factor for conservative performance calculations

### Airport & Weather Data

- **Airport Database**: Integrated FAA NASR data for US airports
- **OurAirports Data**: International airport coverage with runway information
- **Live Weather**: Fetch METAR/TAF data automatically or input custom conditions
- **Location-Based Search**: Find nearby airports using device location
- **Favorites & Recents**: Quick access to frequently used airports

### Advanced Features

- **NOTAM Support**: Account for runway contamination, obstacles, and displaced thresholds
- **Widget Support**: Home screen widget displaying selected airport runway data
- **Timezone Support**: View times in UTC or airport local time
- **Custom Fuel Density**: Adjust for actual fuel density variations

## Technical Overview

### Architecture

#### Technology Stack

- **Framework**: SwiftUI + Swift 6.0
- **Data Persistence**: SwiftData for local storage
- **Shared Data**: App Groups for widget communication
- **Settings Management**: Defaults library for type-safe UserDefaults
- **Error Monitoring**: BugSnag for crash reporting and performance monitoring

#### Project Structure

```
SF50 TOLD/
├── SF50 TOLD/                  # Main iOS app target
│   ├── SF50_TOLDApp.swift      # App entry point & initialization
│   ├── Views/                  # SwiftUI views
│   │   ├── ContentView.swift   # Main tab view container
│   │   ├── Performance/        # Takeoff/Landing calculation views
│   │   ├── Pickers/            # Airport, runway, weather pickers
│   │   ├── Settings/           # App settings & configuration
│   │   ├── Loading/            # Airport data loading UI
│   │   └── TLR/                # Takeoff/Landing Report generation
│   ├── Loaders/                # Airport data loading logic
│   └── TLR/                    # HTML report generation
├── SF50 Shared/                # Shared business logic
│   ├── Models/                 # SwiftData models (Airport, Runway, NOTAM)
│   ├── Performance/            # Performance calculation engines
│   │   ├── Models/             # G1 & G2+ performance models
│   │   └── ViewModel/          # Takeoff/Landing view models
│   ├── Weather/                # METAR/TAF parsing
│   ├── NearestAirport/         # Location-based airport search
│   └── Defaults.swift          # Shared settings definitions
├── SF50 Runways/               # Widget extension
├── SF50 SharedTests/           # Unit tests
└── SF50 TOLDUITests/           # UI tests
```

### Key Components

#### 1. Performance Models

Two calculation approaches are implemented:

- **Tabular Model** (`DataTable.swift`): Multi-dimensional interpolation of official AFM tables
- **Regression Model**: Polynomial regression models

Performance data is sourced from:

- G1: P/N 31452-001 Rev A1
- G2-G2+: P/N 31452-002 Rev 2
- Updated Thrust Schedule: P/N 31452-111 Rev 1

#### 2. Data Layer

- **SwiftData Models**: `Airport`, `Runway`, `NOTAM`
- **Persistence**: Group container (`group.codes.tim.TOLD`) for widget sharing
- **Schema Versioning**: Currently on schema v3 with migration support

#### 3. Airport Data Loading

- **NASR Integration**: Downloads and parses FAA's 28-day NASR cycle
- **OurAirports**: CSV parsing for international airports
- **Background Loading**: Asynchronous download with progress tracking
- **User Consent**: Required before downloading large datasets

#### 4. Weather Integration

- **METAR/TAF Parsing**: Custom XML parser for NOAA Aviation Weather Service
- **Manual Entry**: Full manual weather input with validation
- **Cached Results**: Weather data cached to reduce API calls

#### 5. Widget Extension

- **WidgetKit**: Lock screen and home screen widgets
- **Shared ModelContainer**: Reads from app group container
- **Auto-Refresh**: Updates when selected airport changes

### Performance Calculation Flow

1. **Input Collection**: User selects airport, runway, enters weight/fuel
2. **Weather Data**: Fetch live METAR or accept manual input
3. **Density Altitude**: Calculate from field elevation, temperature, altimeter
4. **Wind Components**: Decompose wind into headwind/crosswind
5. **Table Lookup**: Interpolate base performance from AFM tables
6. **Adjustments**: Apply corrections for:
   - Slope
   - Tailwind
   - Anti-ice
   - Runway contamination (wet/icy)
7. **Safety Factor**: Multiply by user-configured factor (default: 1.0)
8. **Results Display**: Show distances, speeds, climb gradients

### Testing

#### Unit Tests

- `DataTableTests`: Multi-dimensional interpolation validation
- `TabularPerformanceModelTests`: G1/G2+ model accuracy
- `RegressionPerformanceModelTests`: Regression model validation
- `METARXMLParserTests`: Weather parsing edge cases

#### UI Tests

- End-to-end takeoff/landing calculation flows
- Airport search and selection
- Weather input validation
- Performance regression tests against known values

### Build & Release

#### CI/CD

- **GitHub Actions**: Automated testing on push/PR
- **Linters**: SwiftLint + swift-format
- **Test Plans**: Separate unit and UI test plans

#### Fastlane

- `fastlane screenshots`: Generate localized screenshots

### Development Setup

#### Prerequisites

- Xcode 16.0+
- iOS 18.0+ deployment target
- Swift 6.0
- Ruby + Bundler (for Fastlane)

#### Dependencies

Managed via Swift Package Manager:

- **Bugsnag**: Error monitoring
- **BugsnagPerformance**: Performance monitoring
- **Defaults**: Type-safe UserDefaults wrapper
- **SwiftNASR**: NASR data parsing
- **ZIPFoundation**: NASR archive extraction
- **swift-collections**: OrderedDictionary for NOTAM ordering

### Data Files

Located in `Data/`:

- **AFM Tables**: CSV files containing official performance tables
- **make-tables/**: Python scripts to convert AFM PDFs to CSV
- **make-regressions/**: Python scripts to generate regression coefficients

### Configuration

#### Settings (Defaults)

- `emptyWeight`: Aircraft empty weight
- `fuelDensity`: Jet-A density (lb/gal)
- `safetyFactor`: Multiplier for conservative calculations
- `updatedThrustSchedule`: Toggle G2+ thrust schedule
- `useRegressionModel`: Enable experimental regression models

#### Environment

- `UI-TESTING` launch argument: Resets app state for UI tests
- Group container: `group.codes.tim.TOLD`
- WeatherKit entitlement required for weather data
