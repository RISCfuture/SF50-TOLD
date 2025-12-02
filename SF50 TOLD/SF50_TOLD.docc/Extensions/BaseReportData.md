# ``SF50_TOLD/BaseReportData``

## Overview

``BaseReportData`` implements the Template Method design pattern for TLR
data generation. The base class provides the algorithm structure while
subclasses (``TakeoffReportData`` and ``LandingReportData``) implement
operation-specific calculations.

## Algorithm Flow

The ``generate()`` method orchestrates the calculation pipeline:

1. **Generate Runway Info**: For each runway, determine maximum weight and
   limiting factor using ``determineMaxWeight(runway:)``

2. **Generate Scenarios**: For each scenario, calculate performance for all
   runways using ``calculatePerformanceForAllRunways(scenario:)``

3. **Return Output**: Package results into ``ReportOutput``

## Binary Search

The ``binarySearchMaxWeight(runway:min:max:increment:isValid:)`` method finds
the maximum valid weight using binary search. Starting from the maximum
possible weight, it narrows down to the highest weight that satisfies all
constraints (AFM limits, runway length, obstacle/climb requirements).

## Topics

### Generating Reports

- ``generate()``
- ``generateRunwayInfo()``
- ``generateScenarios()``
- ``calculatePerformanceForAllRunways(scenario:)``

### Template Methods

- ``operation()``
- ``maxWeight()``
- ``calculatePerformance(for:conditions:config:)``
- ``determineMaxWeight(runway:)``
- ``createScenario(name:runways:)``

### Weight Search

- ``binarySearchMaxWeight(runway:min:max:increment:isValid:)``
