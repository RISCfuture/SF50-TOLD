# ``SF50_TOLD/AirportLoader``

## Overview

``AirportLoader`` handles the complete airport data update pipeline as a
`@ModelActor`. It downloads pre-processed airport data from GitHub, decompresses
it, and imports it into the shared SwiftData store. It creates
``SF50_Shared/Airport`` and ``SF50_Shared/Runway`` model instances.

## Data Format

Airport data is stored as an LZMA-compressed property list containing:

- Airport records (location ID, name, coordinates, elevation, etc.)
- Runway records (heading, length, distances, gradient)
- NASR cycle information
- OurAirports last update timestamp

## Usage

Create a loader with the model container and call ``load()``:

```swift
let loader = AirportLoader(modelContainer: container)
let (cycle, lastUpdated) = try await loader.load()
```

## Progress Monitoring

Poll the ``state`` property to track progress:

```swift
Task {
    while true {
        switch await loader.state {
        case .downloading(let progress):
            print("Downloading: \(progress ?? 0)%")
        case .loading(let progress):
            print("Importing: \(progress ?? 0)%")
        // ...
        }
        try? await Task.sleep(for: .seconds(0.25))
    }
}
```

## Topics

### Loading

- ``load()``
- ``state``

### State

- ``State``

### Errors

- ``Errors``
