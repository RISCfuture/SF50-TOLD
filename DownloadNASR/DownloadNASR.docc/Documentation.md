# ``DownloadNASR``

macOS tool for processing FAA NASR and OurAirports data into app-ready format.

## Overview

DownloadNASR is a macOS utility that processes airport and runway data from
multiple sources into a compressed format used by SF50 TOLD. The tool downloads
raw data, merges and deduplicates it, and optionally uploads to GitHub for
distribution.

## Data Pipeline

The tool processes data through several stages:

1. **Download FAA NASR**: Retrieve current cycle data from FAA
2. **Download OurAirports**: Retrieve international airport CSV data
3. **Parse and Filter**: Extract relevant airport/runway records
4. **Merge**: Combine datasets with NASR taking priority
5. **Compress**: Create LZMA-compressed property list
6. **Upload**: Push to GitHub repository (optional)

## Output Format

The compressed `.plist.lzma` file contains:
- Airport records (ID, name, coordinates, elevation, timezone)
- Runway records (heading, length, distances, surface type)
- NASR cycle identifier
- OurAirports last update timestamp

## Topics

### Data Processing

- <doc:DataProcessingPipeline>
- ``NASRProcessor``
- ``OurAirportsLoader``
- ``OurAirportData``
- ``OurRunwayData``
- ``ProcessorViewModel``

### GitHub Upload

- ``GitHubUploader``
- ``GitHubAPIError``
- ``KeychainManager``
- ``KeychainError``
