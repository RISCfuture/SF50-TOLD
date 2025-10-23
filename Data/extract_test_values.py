#!/usr/bin/env python3
import csv
from pathlib import Path

base_path = Path("/Users/tmorgan/Repositories/Applications/SF50-TOLD/SF50 Shared/Data/g1")

def read_csv(filepath):
    """Read CSV and return dict with (alt, temp, weight) -> value"""
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        # Handle both column names
        alt_col = 'pressure_alt_ft' if 'pressure_alt_ft' in reader.fieldnames else 'altitude_ft'
        return {
            (int(row[alt_col]), int(float(row['oat_c'])), int(row['weight_lb'])): float(row['value'])
            for row in reader
        }

# Define test cases (weight, altitude, temp)
base_test_cases = [
    (6000, 0, -20),
    (6000, 0, 0),
    (6000, 0, 10),  # Changed from 20/40
    (5500, 0, -20),
    (5500, 0, 0),
    (5500, 0, 10),
    (5000, 0, 0),
    (5000, 0, 10),
    (4500, 0, 0),
    (4500, 0, 10),
    (6000, 10000, -15),
    (6000, 20000, -35),
    (5000, 10000, -15),
    (4500, 20000, -35),
]

print("=" * 80)
print("ENROUTE CLIMB - NORMAL")
print("=" * 80)

# Gradient Normal
data = read_csv(base_path / "enroute climb/normal/gradient.csv")
print("\nGradient (ft/nmi):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Rate Normal
data = read_csv(base_path / "enroute climb/normal/rate.csv")
print("\nRate (ft/min):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Speed Normal
data = read_csv(base_path / "enroute climb/normal/speed.csv")
print("\nSpeed (KIAS):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

print("\n" + "=" * 80)
print("ENROUTE CLIMB - ICE CONTAMINATED")
print("=" * 80)

# Gradient Ice
data = read_csv(base_path / "enroute climb/ice contaminated/gradient.csv")
print("\nGradient (ft/nmi):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Rate Ice
data = read_csv(base_path / "enroute climb/ice contaminated/rate.csv")
print("\nRate (ft/min):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Speed Ice
data = read_csv(base_path / "enroute climb/ice contaminated/speed.csv")
print("\nSpeed (KIAS):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

print("\n" + "=" * 80)
print("TIME/FUEL/DISTANCE TO CLIMB")
print("=" * 80)

# Time
data = read_csv(base_path / "time fuel distance to climb/time.csv")
print("\nTime (min):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Fuel
data = read_csv(base_path / "time fuel distance to climb/fuel.csv")
print("\nFuel (US gal):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")

# Distance
data = read_csv(base_path / "time fuel distance to climb/distance.csv")
print("\nDistance (nm):")
for weight, alt, temp in base_test_cases:
    key = (alt, temp, weight)
    if key in data:
        print(f"      ({weight}, {alt}, {temp}, {int(data[key])}),")
    else:
        print(f"      // NOT FOUND: ({weight}, {alt}, {temp})")
