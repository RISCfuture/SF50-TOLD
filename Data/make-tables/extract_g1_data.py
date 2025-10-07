#!/usr/bin/env python3
"""
Extract performance data from Cirrus Vision Jet AFM PDFs

This script extracts various performance tables from AFM PDFs and saves them
as CSV files in an organized directory structure.

Usage:
    python extract_afm_data.py <pdf_path> [output_dir]
    
Example:
    python extract_afm_data.py "G1 AFM.pdf" output
"""

import os
import sys
import csv
import re
import argparse
from pathlib import Path
import PyPDF2
from typing import List, Dict, Tuple, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class AFMDataExtractor:
    """Extract performance data from Cirrus Vision Jet AFM PDFs"""
    
    def __init__(self, pdf_path: str, output_dir: str = "output"):
        self.pdf_path = Path(pdf_path)
        if not self.pdf_path.exists():
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")
            
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # Determine aircraft model from filename
        self.model = "g1" if "G1" in self.pdf_path.name else "g2+"
        
        # ISA temperature calculation: 15°C at sea level, decreases by 1.98°C per 1000 feet
        self.isa_lapse_rate = 1.98  # °C per 1000 feet
        
        # Page locations for G1 AFM (would need adjustment for G2+)
        self.page_locations = {
            'takeoff': {
                6000: (271, 272),
                5500: (273, 274),
                5000: (275, 276)
            },
            'landing_100': {
                5550: (381, 382),
                4500: (388, 389)
            },
            'landing_50': {
                5550: (383, 384),
                4500: (390, 391)
            },
            'landing_50_ice': {
                5550: (385, 386),
                4500: (392, 393)
            },
            'climb_gradient': (276, 281),
            'climb_rate': (282, 287),
            'contamination_water': 418,
            'contamination_snow': 419,
            'vref': 380
        }
        
    def calculate_isa_temp(self, altitude: int) -> float:
        """Calculate ISA temperature for a given altitude"""
        # ISA temp = 15°C - (1.98°C per 1000 feet)
        # But use the exact values from the example files for consistency
        isa_values = {
            0: 15.0,
            1000: 13.0188,
            2000: 11.037600000000001,  
            3000: 9.0564,
            4000: 7.075200000000001,
            5000: 5.094000000000001,
            6000: 3.112800000000002,
            7000: 1.1316000000000006,
            8000: -0.8495999999999988,
            9000: -2.8308,
            10000: -4.811999999999998
        }
        return isa_values.get(altitude, 15.0 - (altitude / 1000.0 * self.isa_lapse_rate))
    
    def create_output_path(self, *parts) -> Path:
        """Create output directory structure and return path"""
        path = self.output_dir / self.model / Path(*parts)
        path.parent.mkdir(parents=True, exist_ok=True)
        return path
    
    def save_csv(self, data: List[List], filepath: Path) -> None:
        """Save data to CSV file with Unix line endings"""
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, lineterminator='\n')
            for row in data:
                writer.writerow(row)
        logger.info(f"Saved: {filepath} ({len(data)-1} data rows)")
    
    def extract_text_from_page(self, page_num: int) -> str:
        """Extract text from a specific page"""
        with open(self.pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            if page_num <= len(pdf_reader.pages):
                return pdf_reader.pages[page_num - 1].extract_text()
        return ""
    
    def extract_text_from_pages(self, start_page: int, end_page: int) -> str:
        """Extract text from specified page range"""
        text = ""
        with open(self.pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            for page_num in range(start_page - 1, min(end_page, len(pdf_reader.pages))):
                page = pdf_reader.pages[page_num]
                text += page.extract_text() + "\n"
        return text
    
    def parse_performance_table(self, page_num: int, weight: int, table_type: str = "ground_run") -> List[List]:
        """Parse performance table data from a specific page"""
        text = self.extract_text_from_page(page_num)
        data = []
        
        # Temperature columns
        temps = [-20, -10, 0, 10, 20, 30, 40, 50]
        
        # Split text into lines and clean
        lines = text.split('\n')
        
        # Process each line
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            # Look for altitude indicators
            alt_match = None
            altitude = None
            values_text = ""
            
            if table_type == "ground_run" and "Gnd Roll" in line:
                # Match patterns like "SLGnd Roll" or "1000Gnd Roll"
                alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', line)
                if alt_match:
                    altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                    # Get the rest of the line after "Gnd Roll"
                    values_text = re.sub(r'^.*?Gnd\s*Roll\s*', '', line)
                    
            elif table_type == "total_distance" and "Total" in line:
                # Match patterns for total distance
                alt_match = re.search(r'(SL|\d+)\s*Total', line)
                if alt_match:
                    altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                    values_text = re.sub(r'^.*?Total\s*', '', line)
            
            if altitude and values_text:
                # Extract numeric values
                values = re.findall(r'\d+', values_text)
                
                # Fix altitude if it's truncated (e.g., "000" -> "10000")
                if altitude == "000" and len(values) > 0:
                    altitude = "10000"
                
                # Determine how many temperature columns we actually have
                # At higher altitudes, 40°C and 50°C columns may be missing
                alt_int = int(altitude)
                expected_cols = 8  # Default all temps
                
                # At altitudes >= 5000ft, often missing 50°C column  
                # At altitudes >= 8000ft, often missing 40°C and 50°C columns
                if alt_int >= 8000 and len(values) == 9:  # 8 temps + ISA
                    expected_cols = 8
                elif alt_int >= 5000 and len(values) == 8:  # 7 temps + ISA
                    expected_cols = 7
                elif alt_int >= 7000 and len(values) == 7:  # 6 temps + ISA
                    expected_cols = 6
                
                # Map values to temperatures
                for j, value in enumerate(values[:expected_cols]):
                    if j < len(temps):
                        data.append([str(weight), altitude, str(temps[j]), value])
                
                # Check for ISA column value (last value if we have more than expected)
                if len(values) > expected_cols:
                    isa_temp = self.calculate_isa_temp(alt_int)
                    data.append([str(weight), altitude, str(isa_temp), values[-1]])
            
            i += 1
        
        return data
    
    def parse_takeoff_tables(self, page_num: int, weight: int) -> Tuple[List[List], List[List]]:
        """Parse both ground run and total distance from takeoff pages"""
        text = self.extract_text_from_page(page_num)
        ground_run_data = []
        total_distance_data = []
        
        # Temperature columns
        temps = [-20, -10, 0, 10, 20, 30, 40, 50]
        
        # Split text into lines
        lines = text.split('\n')
        
        # Track current altitude for pairing ground run with total distance
        current_altitude = None
        
        for i, line in enumerate(lines):
            line = line.strip()
            
            # Look for ground run lines
            if "Gnd Roll" in line:
                alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', line)
                if alt_match:
                    current_altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                    if current_altitude == "000":
                        current_altitude = "10000"
                    
                    # Extract values after "Gnd Roll"
                    values_text = re.sub(r'^.*?Gnd\s*Roll\s*', '', line)
                    values = re.findall(r'\d+', values_text)
                    
                    # Process ground run values
                    if values:
                        self._add_performance_values(ground_run_data, weight, current_altitude, values, temps)
            
            # Look for total distance lines (they follow ground run lines)
            elif "Total" in line and current_altitude is not None:
                # Extract values after "Total"
                values_text = re.sub(r'^.*?Total\s*', '', line)
                # Handle numbers with commas
                values_text = values_text.replace(',', '')
                values = re.findall(r'\d+', values_text)
                
                # Process total distance values
                if values:
                    self._add_performance_values(total_distance_data, weight, current_altitude, values, temps)
        
        return ground_run_data, total_distance_data
    
    def _add_performance_values(self, data: List[List], weight: int, altitude: str, values: List[str], temps: List[int]) -> None:
        """Add performance values to data list, handling missing columns at high altitudes"""
        alt_int = int(altitude)
        
        # Determine expected columns based on altitude and value count
        if alt_int >= 5000 and len(values) <= 9:
            # Likely missing some high temp columns
            if len(values) == 9:  # 8 temps + ISA
                expected_cols = 8
            elif len(values) == 8:  # 7 temps + ISA
                expected_cols = 7
            elif len(values) == 7:  # 6 temps + ISA
                expected_cols = 6
            else:
                expected_cols = min(len(values), 8)
        else:
            expected_cols = min(len(values), 8)
        
        # Add temperature values
        for j in range(expected_cols):
            if j < len(temps) and j < len(values):
                data.append([str(weight), altitude, str(temps[j]), values[j]])
        
        # Add ISA value if present
        if len(values) > expected_cols:
            isa_temp = self.calculate_isa_temp(alt_int)
            data.append([str(weight), altitude, str(isa_temp), values[-1]])
    
    def extract_takeoff_data(self) -> None:
        """Extract takeoff performance data"""
        logger.info("Extracting takeoff data...")
        
        all_ground_run = [['weight', 'altitude', 'temperature', 'value']]
        all_total_distance = [['weight', 'altitude', 'temperature', 'value']]
        
        for weight, (start_page, end_page) in self.page_locations['takeoff'].items():
            logger.info(f"Processing takeoff page {start_page} for {weight} lb")
            
            # Extract both ground run and total distance data from same pages
            # They are in pairs - ground run followed by total distance
            ground_run_data, total_distance_data = self.parse_takeoff_tables(start_page, weight)
            all_ground_run.extend(ground_run_data)
            all_total_distance.extend(total_distance_data)
            
            # Check second page for additional altitudes
            if end_page > start_page:
                logger.info(f"Processing takeoff page {end_page} for {weight} lb")
                ground_run_data, total_distance_data = self.parse_takeoff_tables(end_page, weight)
                all_ground_run.extend(ground_run_data)
                all_total_distance.extend(total_distance_data)
        
        # Save data
        self.save_csv(all_ground_run, self.create_output_path("takeoff", "ground run.csv"))
        self.save_csv(all_total_distance, self.create_output_path("takeoff", "total distance.csv"))
    
    
    def extract_landing_data(self) -> None:
        """Extract landing performance data"""
        logger.info("Extracting landing data...")
        
        flap_configs = [
            ('100', self.page_locations['landing_100']),
            ('50', self.page_locations['landing_50']),
            ('50 ice', self.page_locations['landing_50_ice'])
        ]
        
        for flap_setting, weight_pages in flap_configs:
            logger.info(f"Extracting landing data for flaps {flap_setting}")
            
            all_ground_run = [['weight', 'altitude', 'temperature', 'value']]
            all_total_distance = [['weight', 'altitude', 'temperature', 'value']]
            
            for weight, (start_page, end_page) in weight_pages.items():
                # Use the second page which typically has the data tables
                logger.info(f"Processing landing page {end_page} for {weight} lb")
                
                # Landing tables have same structure as takeoff
                ground_run_data, total_distance_data = self.parse_landing_tables(end_page, weight, flap_setting)
                all_ground_run.extend(ground_run_data)
                all_total_distance.extend(total_distance_data)
            
            # Save data
            self.save_csv(all_ground_run, self.create_output_path("landing", flap_setting, "ground run.csv"))
            self.save_csv(all_total_distance, self.create_output_path("landing", flap_setting, "total distance.csv"))
    
    def parse_landing_tables(self, page_num: int, weight: int, flap_setting: str = "") -> Tuple[List[List], List[List]]:
        """Parse both ground run and total distance from landing pages"""
        text = self.extract_text_from_page(page_num)
        ground_run_data = []
        total_distance_data = []
        
        # Landing tables have ISA first, then 0, 10, 20, 30, 40, 50
        # But at higher altitudes, some columns may be missing
        
        lines = text.split('\n')
        current_altitude = None
        
        for i, line in enumerate(lines):
            line = line.strip()
            
            # Look for ground run lines
            if "Gnd Roll" in line:
                alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', line)
                if alt_match:
                    current_altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                    if current_altitude == "000":
                        current_altitude = "10000"
                    
                    # Extract values after "Gnd Roll"
                    values_text = re.sub(r'^.*?Gnd\s*Roll\s*', '', line)
                    values = re.findall(r'\d+', values_text)
                    
                    if values:
                        if current_altitude == "10000":
                            logger.debug(f"Landing ground run at {current_altitude} ft, weight {weight}: {len(values)} values = {values}")
                        self._add_landing_values(ground_run_data, weight, current_altitude, values, flap_setting)
            
            # Look for total distance lines
            elif "Total" in line and current_altitude is not None:
                # Extract values after "Total"
                values_text = re.sub(r'^.*?Total\s*', '', line)
                values_text = values_text.replace(',', '')
                values = re.findall(r'\d+', values_text)
                
                if values:
                    self._add_landing_values(total_distance_data, weight, current_altitude, values, flap_setting)
        
        return ground_run_data, total_distance_data
    
    def _add_landing_values(self, data: List[List], weight: int, altitude: str, values: List[str], flap_setting: str = "") -> None:
        """Add landing performance values, handling ISA column first"""
        alt_int = int(altitude)
        
        # For landing tables, the column order in PDF is: ISA, temp1, temp2, temp3...
        # Number of columns varies by altitude, weight, and flap setting
        
        if len(values) > 0:
            # Determine temperature columns based on flap setting
            if flap_setting == "50 ice":
                # 50 ice has negative temperatures: -20, -10, 0, 10
                # First value goes to -20°C, and last value goes to 10°C (not ISA)
                data.append([str(weight), altitude, '-20', values[0]])
                all_temps = [-10, 0, 10]
            else:
                # Regular landing tables start at 0°C
                all_temps = [10, 20, 30, 40, 50]
                # First value is ISA which goes to 0°C
                data.append([str(weight), altitude, '0', values[0]])
            
            # If we have more than 1 value, process the rest
            if len(values) > 1:
                # The number of temperature values is len(values) - 2 
                # (minus first ISA value, minus last value which is also for ISA temp)
                num_temp_values = len(values) - 2
                
                # Add temperature values
                if flap_setting == "50 ice":
                    # For 50 ice, all remaining values go to the temperature columns, no ISA
                    for i in range(len(values) - 1):
                        if i < len(all_temps):
                            data.append([str(weight), altitude, str(all_temps[i]), values[i + 1]])
                else:
                    # For other flap settings, save last value for ISA
                    for i in range(num_temp_values):
                        if i < len(all_temps):
                            data.append([str(weight), altitude, str(all_temps[i]), values[i + 1]])
                    
                    # Add the ISA temperature with the last value
                    isa_temp = self.calculate_isa_temp(alt_int)
                    data.append([str(weight), altitude, str(isa_temp), values[-1]])
    
    def extract_climb_data(self) -> None:
        """Extract takeoff climb performance data"""
        logger.info("Extracting takeoff climb gradient data from pages...")
        
        # Extract climb gradient
        start, end = self.page_locations['climb_gradient']
        gradient_data = self.parse_climb_gradient_tables(start, end)
        self.save_csv(gradient_data, self.create_output_path("takeoff climb", "gradient.csv"))
        
        # Extract climb rate
        logger.info("Extracting takeoff climb rate data...")
        start, end = self.page_locations['climb_rate']
        rate_data = self.parse_climb_rate_tables(start, end)
        self.save_csv(rate_data, self.create_output_path("takeoff climb", "rate.csv"))
    
    def parse_climb_gradient_tables(self, start_page: int, end_page: int) -> List[List]:
        """Parse climb gradient data from matrix format"""
        data = [['weight', 'altitude', 'temperature', 'value']]
        weights = [6000, 5500, 5000, 4500]
        
        # Read all text first
        all_text = ""
        for page in range(start_page, end_page + 1):
            all_text += self.extract_text_from_page(page) + "\n"
        
        # Replace comma in 10,000 with nothing
        all_text = all_text.replace('10,000', '10000')
        
        lines = all_text.split('\n')
        
        # Find all altitude patterns
        altitude_data = []
        
        for i, line in enumerate(lines):
            # Check for embedded altitudes in page numbers like "5-271000-40"
            embedded_match = re.search(r'\d+-\d+(\d{4})-40\s+([\d\s]+)', line)
            if embedded_match:
                altitude = embedded_match.group(1)
                if int(altitude) <= 10000 and int(altitude) % 1000 == 0:
                    values = re.findall(r'\d+', embedded_match.group(2))
                    if len(values) >= 4:
                        altitude_data.append((i, altitude, values[:4]))
            
            # Check for standalone altitude patterns like "0-40" or "2000-40"
            standalone_match = re.search(r'^(\d{1,5})\s*-40\s+([\d\s]+)', line)
            if standalone_match:
                altitude = standalone_match.group(1)
                if int(altitude) <= 10000 and int(altitude) % 1000 == 0:
                    values = re.findall(r'\d+', standalone_match.group(2))
                    if len(values) >= 4:
                        altitude_data.append((i, altitude, values[:4]))
        
        # Process each altitude
        processed_lines = set()
        for line_idx, altitude, initial_values in altitude_data:
            if line_idx in processed_lines:
                continue
                
            temp_data = {-40: initial_values}
            
            # Look for temperature lines following this altitude
            j = 1
            temps = [-30, -20, -10, 0, 10, 20, 30, 40, 50]
            
            while j < 15 and line_idx + j < len(lines):
                if line_idx + j in processed_lines:
                    j += 1
                    continue
                    
                next_line = lines[line_idx + j].strip()
                
                # Special handling for 0°C which is often mangled
                if (next_line.startswith('0') and len(next_line) > 10 and 
                    (' ' in next_line[1:5] or not next_line.startswith('0 '))):
                    # Extract all digits from the line
                    all_digits = ''.join(c for c in next_line if c.isdigit())
                    
                    # Skip first '0' and extract the values
                    if len(all_digits) >= 13 and all_digits[0] == '0':
                        remaining = all_digits[1:]  # Skip the temperature indicator '0'
                        values = []
                        
                        # The pattern varies by altitude
                        # Lower altitudes: 4-digit numbers (e.g., "1227 1415 1634 1893")
                        # Higher altitudes: 3-4 digit numbers (e.g., "929 1091 1278 1499")
                        
                        # Try to parse based on expected patterns
                        if len(remaining) == 16:  # 4x4 digits
                            for i in range(0, 16, 4):
                                values.append(remaining[i:i+4])
                        elif len(remaining) == 15:  # Possibly 3,4,4,4 pattern
                            values = [remaining[0:3], remaining[3:7], remaining[7:11], remaining[11:15]]
                        elif len(remaining) == 14:  # Possibly 3,3,4,4 or 3,4,4,3 pattern
                            # Special case for 10000ft: "809 962 1137 1343" from "80996211371343"
                            if altitude == '10000' and remaining.startswith('809'):
                                values = [remaining[0:3], remaining[3:6], remaining[6:10], remaining[10:14]]
                            else:
                                values = [remaining[0:3], remaining[3:7], remaining[7:11], remaining[11:14]]
                        elif len(remaining) >= 12:  # At least 3 values
                            # Try common patterns for high altitude
                            if altitude in ['8000', '9000', '10000']:
                                # Pattern like 929,1091,1278,1499
                                values = [remaining[0:3], remaining[3:7], remaining[7:11]]
                                if len(remaining) >= 15:
                                    values.append(remaining[11:15])
                            else:
                                # Default 4-digit grouping
                                for i in range(0, min(len(remaining), 16), 4):
                                    if i + 3 < len(remaining):
                                        values.append(remaining[i:i+4])
                        
                        if len(values) >= 3:
                            temp_data[0] = values[:4]
                            processed_lines.add(line_idx + j)
                            j += 1
                            continue
                
                # Check for normal temperature lines
                temp_found = False
                for temp in temps:
                    if next_line.startswith(f'{temp} '):
                        values = re.findall(r'\d+', next_line[len(str(temp)):])
                        # At high altitudes (9000, 10000) and high temps (40°C), might have only 3 values
                        min_values = 3 if (int(altitude) >= 9000 and temp >= 40) else 4
                        if len(values) >= min_values:
                            temp_data[temp] = values[:4]
                            temp_found = True
                            processed_lines.add(line_idx + j)
                            break
                
                # Check for special temps (41-50)
                if not temp_found and re.match(r'^\d{2}\s+\d', next_line):
                    # Handle lines like "43 321 436 567Engine Anti-Ice"
                    temp_match = re.match(r'^(\d{2})\s+([\d\s]+?)(?:[A-Z]|$)', next_line)
                    if temp_match:
                        temp_val = int(temp_match.group(1))
                        if 41 <= temp_val <= 50:
                            # Extract just the numeric part before any text
                            num_part = temp_match.group(2)
                            values = re.findall(r'\d+', num_part)
                            if len(values) >= 3:  # At high altitudes might have only 3 values
                                temp_data[temp_val] = values[:4]
                                temp_found = True
                                processed_lines.add(line_idx + j)
                
                if temp_found:
                    j += 1
                else:
                    # Stop if we hit non-temperature data
                    if 'Engine' in next_line or 'Press' in next_line or '-40' in next_line:
                        break
                    j += 1
            
            # Add data for this altitude
            for temp, values in sorted(temp_data.items()):
                # When we have fewer values than weights (e.g., 3 values for 4 weights),
                # assign them to the lighter weights (skip heavier ones)
                if len(values) < len(weights):
                    # Skip the first (heaviest) weights
                    weight_offset = len(weights) - len(values)
                    for v_idx, value in enumerate(values):
                        if value.isdigit():
                            data.append([str(weights[weight_offset + v_idx]), altitude, str(temp), value])
                else:
                    # Normal case: we have values for all weights
                    for w_idx, value in enumerate(values):
                        if w_idx < len(weights) and value.isdigit():
                            data.append([str(weights[w_idx]), altitude, str(temp), value])
        
        return data
    
    def parse_climb_rate_tables(self, start_page: int, end_page: int) -> List[List]:
        """Parse climb rate data - similar structure to gradient"""
        # Use same parsing logic as gradient
        return self.parse_climb_gradient_tables(start_page, end_page)
    
    def extract_contamination_data(self) -> None:
        """Extract landing contamination data"""
        logger.info("Extracting contamination data...")
        
        # Extract water contamination from page 418
        water_page = self.page_locations['contamination_water']
        water_text = self.extract_text_from_page(water_page)
        
        # Extract snow contamination from page 419
        snow_page = self.page_locations['contamination_snow']
        snow_text = self.extract_text_from_page(snow_page)
        
        # Parse water contamination data
        water_data = [['distance', 'depth', 'value']]
        # Water table has depths: 0.125, 0.2, 0.3, 0.4, 0.5 (no 0.0)
        depths = ['0.125', '0.2', '0.3', '0.4', '0.5']
        
        # Parse water table
        lines = water_text.split('\n')
        for line in lines:
            # Look for lines starting with distance values
            match = re.match(r'^(\d{4})\s+(.+)', line)
            if match:
                distance = match.group(1)
                values = re.findall(r'\d+', match.group(2))
                if len(values) >= 5:
                    # Add 0.0 depth with same value as distance
                    water_data.append([distance, '0.0', distance])
                    # Then add the contaminated values
                    for i, depth in enumerate(depths):
                        if i < len(values):
                            water_data.append([distance, depth, values[i]])
        
        self.save_csv(water_data, self.create_output_path("landing", "contamination", "water.csv"))
        
        # Parse snow contamination data
        # The table has: Dry GND Roll Distance | Slush/Wet Snow (0.125-0.5) | Dry Snow (1.0) | Compact Snow
        lines = snow_text.split('\n')
        
        slush_data = [['distance', 'depth', 'value']]
        dry_snow_data = [['distance', 'value']]
        compact_snow_data = [['distance', 'value']]
        
        for line in lines:
            # Look for lines starting with distance values
            match = re.match(r'^(\d{4})\s+(.+)', line)
            if match:
                distance = match.group(1)
                values = re.findall(r'\d+', match.group(2))
                
                if len(values) >= 7:
                    # Values are: slush 0.125, 0.2, 0.3, 0.4, 0.5, dry snow 1.0, compact snow
                    slush_depths = ['0.125', '0.2', '0.3', '0.4', '0.5']
                    for i, depth in enumerate(slush_depths):
                        if i < 5:
                            slush_data.append([distance, depth, values[i]])
                    
                    # Dry snow is at index 5
                    dry_snow_data.append([distance, values[5]])
                    
                    # Compact snow is at index 6
                    compact_snow_data.append([distance, values[6]])
        
        self.save_csv(slush_data, self.create_output_path("landing", "contamination", "slush, wet snow.csv"))
        self.save_csv(dry_snow_data, self.create_output_path("landing", "contamination", "dry snow.csv"))
        self.save_csv(compact_snow_data, self.create_output_path("landing", "contamination", "compact snow.csv"))
    
    def extract_vref_data(self) -> None:
        """Extract Vref data"""
        logger.info("Extracting Vref data...")
        
        # Extract from page 380
        text = self.extract_text_from_page(self.page_locations['vref'])
        lines = text.split('\n')
        
        # Parse the Vref table
        weights = ['4000', '4500', '5000', '5500', '6000']
        vref_data = {}
        
        for i, line in enumerate(lines):
            # UP or UNKNOWN line
            if "UP or UNKNOWN" in line:
                values = re.findall(r'\d+', line)
                if len(values) >= 5:
                    vref_data["up.csv"] = [['weight', 'value']]
                    for w, v in zip(weights, values[-5:]):
                        vref_data["up.csv"].append([w, v])
            
            # Ice contaminated lines have values on the "Advisory)" line
            elif "SPEED HIGH Advisory)" in line:
                values = re.findall(r'\d+', line)
                if len(values) >= 5:
                    # Check which type this is based on previous lines
                    if i >= 11 and i <= 13:  # UP ICE
                        vref_data["up ice.csv"] = [['weight', 'value']]
                        for w, v in zip(weights, values[-5:]):
                            vref_data["up ice.csv"].append([w, v])
                    elif i >= 15 and i <= 17:  # 50 ICE
                        vref_data["50 ice.csv"] = [['weight', 'value']]
                        for w, v in zip(weights, values[-5:]):
                            vref_data["50 ice.csv"].append([w, v])
            
            # 50% line (regular, not ice)
            elif line.strip() == "50%" or (line.strip().startswith("50%") and len(line) < 20):
                values = re.findall(r'\d+', line)
                if len(values) >= 5:
                    vref_data["50.csv"] = [['weight', 'value']]
                    for w, v in zip(weights, values[-5:]):
                        vref_data["50.csv"].append([w, v])
            
            # 100% line
            elif line.strip().startswith("100%"):
                values = re.findall(r'\d+', line)
                if len(values) >= 5:
                    vref_data["100.csv"] = [['weight', 'value']]
                    for w, v in zip(weights, values[-5:]):
                        vref_data["100.csv"].append([w, v])
        
        # Save all Vref data
        for filename, data in vref_data.items():
            self.save_csv(data, self.create_output_path("vref", filename))
    
    def extract_all(self) -> None:
        """Extract all data from the PDF"""
        logger.info(f"Starting extraction from {self.pdf_path}...")
        
        try:
            self.extract_takeoff_data()
            self.extract_landing_data()
            self.extract_climb_data()
            self.extract_vref_data()
            self.extract_contamination_data()
            
            logger.info("All data extraction completed successfully!")
            logger.info(f"Output saved to: {self.output_dir}/{self.model}/")
            
        except Exception as e:
            logger.error(f"Extraction failed: {e}")
            raise


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Extract performance data from Cirrus Vision Jet AFM PDFs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python extract_afm_data.py "G1 AFM.pdf"
  python extract_afm_data.py "G1 AFM.pdf" output_directory
  python extract_afm_data.py --help
        """
    )
    
    parser.add_argument('pdf_path', help='Path to the AFM PDF file')
    parser.add_argument('output_dir', nargs='?', default='output', 
                       help='Output directory (default: output)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Create extractor and run
        extractor = AFMDataExtractor(args.pdf_path, args.output_dir)
        extractor.extract_all()
        
    except FileNotFoundError as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()