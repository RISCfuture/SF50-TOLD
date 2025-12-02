# Data Processing Pipeline

Understanding how airport data flows through DownloadNASR.

## Overview

DownloadNASR processes airport and runway data from two primary sources—FAA NASR
and OurAirports—into a compressed format optimized for mobile distribution. This
article explains each stage of the pipeline and the data transformations applied.

## Pipeline Architecture

![Data Processing Pipeline](data-processing-pipeline)

## Stage 1: FAA NASR Download

The FAA publishes National Airspace System Resources (NASR) data every 28 days
(AIRAC cycle). ``NASRProcessor`` uses the SwiftNASR library to:

1. Download the NASR archive for the current cycle
2. Parse airport and runway records
3. Filter to airports with runways ≥500 feet
4. Extract precise runway distances (TORA, TODA, LDA)

NASR data is authoritative for US airports and includes:
- Precise runway geometry (length, distances, gradient)
- Official identifiers (FAA LID, ICAO)
- Touchdown zone elevations
- True headings

## Stage 2: OurAirports Download

``OurAirportsLoader`` downloads community-maintained CSV data to supplement
NASR with international airports:

```swift
let airportsURL = "https://davidmegginson.github.io/ourairports-data/airports.csv"
let runwaysURL = "https://davidmegginson.github.io/ourairports-data/runways.csv"
```

The loader filters to:
- Airport types: `small_airport`, `medium_airport`, `large_airport`
- Runways ≥500 feet
- Excludes water runways

## Stage 3: Merge and Deduplicate

NASR data takes priority over OurAirports. The merge process:

1. Add all NASR airports to the output set
2. Track NASR location IDs in a lookup set
3. For each OurAirports record:
   - Skip if `local_code` matches an existing NASR `locationID`
   - Otherwise add to output

This ensures US airports use authoritative FAA data while international
airports use OurAirports data.

## Stage 4: Data Enrichment

Each airport record is enriched with:

### Timezone Lookup

Using SwiftTimeZoneLookup, each airport gets its local timezone based on
coordinates. This enables local time display in the app.

### Magnetic Variation

Using the ``Geomagnetism`` model (World Magnetic Model), magnetic declination
is calculated for airports without NASR-provided variation data.

## Stage 5: Encoding and Compression

The final data structure is encoded as:

1. **Property List**: Binary plist format for efficient iOS parsing
2. **LZMA Compression**: Reduces file size significantly (~90% reduction)

The output filename follows the pattern: `{cycle}.plist.lzma` (e.g., `2501.plist.lzma`)

## Stage 6: GitHub Upload

If a GitHub token is configured, ``GitHubUploader`` pushes the compressed file
to the SF50-TOLD-Airports repository. The iOS app downloads from this location.

Upload path: `3.0/{cycle}.plist.lzma`

## Data Format

The compressed file contains an ``AirportDataCodable`` structure:

```
AirportDataCodable
├── nasrCycle: Cycle (e.g., 2501)
├── ourAirportsLastUpdated: Date
└── airports: [AirportCodable]
    ├── recordID: String
    ├── locationID: String (FAA LID)
    ├── ICAO_ID: String?
    ├── name: String
    ├── city: String
    ├── dataSource: "nasr" | "ourAirports"
    ├── latitude: Double (degrees)
    ├── longitude: Double (degrees)
    ├── elevation: Double (meters)
    ├── variation: Double (degrees)
    ├── timeZone: String?
    └── runways: [RunwayCodable]
        ├── name: String
        ├── elevation: Double? (meters)
        ├── trueHeading: Double (degrees)
        ├── gradient: Double?
        ├── length: Double (meters)
        ├── takeoffRun: Double? (meters)
        ├── takeoffDistance: Double? (meters)
        ├── landingDistance: Double? (meters)
        ├── isTurf: Bool
        └── reciprocalName: String?
```

## See Also

- ``NASRProcessor``
- ``OurAirportsLoader``
- ``GitHubUploader``
