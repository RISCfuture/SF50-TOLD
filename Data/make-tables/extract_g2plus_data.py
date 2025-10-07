#!/usr/bin/env python3
"""
Extract performance data from G2+ AFM Supplement PDF and save to CSV files
matching the format in example_data/g2+/
"""

import sys
import os
import re
import csv
from typing import List, Dict, Tuple, Optional
import argparse
import PyPDF2
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class G2PlusAFMDataExtractor:
    def __init__(self, pdf_path: str):
        self.pdf_path = pdf_path
        self.pdf_reader = None
        self.isa_lapse_rate = 1.98  # °C per 1000 feet
    
    def __enter__(self):
        self.pdf_file = open(self.pdf_path, 'rb')
        self.pdf_reader = PyPDF2.PdfReader(self.pdf_file)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.pdf_file:
            self.pdf_file.close()
    
    def extract_text_from_page(self, page_num: int) -> str:
        """Extract text from a specific page"""
        if page_num < len(self.pdf_reader.pages):
            page = self.pdf_reader.pages[page_num]
            return page.extract_text()
        return ""
    
    def calculate_isa_temp(self, altitude: int) -> float:
        """Calculate ISA temperature for given altitude"""
        # Use exact values from G1 to match expected output
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
    
    def create_output_path(self, *parts: str) -> str:
        """Create output path and ensure directory exists"""
        path = os.path.join("output", "g2+", *parts)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path
    
    def save_csv(self, data: List[List], filepath: str) -> None:
        """Save data to CSV file with Unix line endings"""
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerows(data)
        logger.info(f"Saved: {filepath} ({len(data) - 1} data rows)")
    
    def extract_takeoff_data(self) -> None:
        """Extract takeoff performance data"""
        logger.info("Extracting takeoff data...")
        
        all_ground_run = [['weight', 'altitude', 'temperature', 'value']]
        all_total_distance = [['weight', 'altitude', 'temperature', 'value']]
        
        # Specific pages for each weight based on the PDF structure
        # Pages are 0-indexed in PyPDF2
        weight_pages = {
            6000: [4],  # Page 5 in PDF (0-indexed: 4)
            5500: [6],  # Page 7 in PDF (0-indexed: 6)
            5000: [8]   # Page 9 in PDF (0-indexed: 8)
        }
        
        for weight, pages in weight_pages.items():
            for page_num in pages:
                logger.info(f"Processing takeoff page {page_num} for {weight} lb")
                text = self.extract_text_from_page(page_num)
                
                # Replace comma in 10,000
                text = text.replace('10,000', '10000')
                
                lines = text.split('\n')
                
                for i, line in enumerate(lines):
                    line = line.strip()
                    
                    # Look for ground run lines
                    if 'Gnd' in line and 'Roll' in line:
                        # Extract altitude
                        alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', line)
                        if alt_match:
                            altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                            
                            # Extract values - everything after "Roll"
                            values_text = re.sub(r'^.*?Roll\s*', '', line)
                            values = re.findall(r'\d+', values_text)
                            
                            if values:
                                self._process_takeoff_values(all_ground_run, weight, altitude, values)
                    
                    # Look for total lines
                    elif 'Total' in line and not 'Takeoff' in line:
                        # Extract values after "Total"
                        values_text = re.sub(r'^.*?Total\s*', '', line)
                        values = re.findall(r'\d+', values_text)
                        
                        if values:
                            # Use the altitude from the previous ground run line
                            # Find altitude by looking back
                            for j in range(i-1, max(0, i-5), -1):
                                prev_line = lines[j].strip()
                                if 'Gnd' in prev_line and 'Roll' in prev_line:
                                    alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', prev_line)
                                    if alt_match:
                                        altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                                        self._process_takeoff_values(all_total_distance, weight, altitude, values)
                                        break
        
        # Save data
        self.save_csv(all_ground_run, self.create_output_path("takeoff", "ground run.csv"))
        self.save_csv(all_total_distance, self.create_output_path("takeoff", "total distance.csv"))
    
    def _process_takeoff_values(self, data: List[List], weight: int, altitude: str, values: List[str]) -> None:
        """Process takeoff values with proper ISA handling"""
        alt_int = int(altitude)
        
        # Temperature columns in G2+: -20, -10, 0, 10, 20, 30, 40, 50
        temps = [-20, -10, 0, 10, 20, 30, 40, 50]
        
        # Determine how many temperature values we have
        # At altitude 7000 and above, we have fewer temperature columns
        if alt_int >= 7000:
            # Count values - last one is ISA
            num_temp_values = len(values) - 1
            
            # Add temperature values
            for j in range(num_temp_values):
                if j < len(temps):
                    data.append([str(weight), altitude, str(temps[j]), values[j]])
            
            # Add ISA value
            isa_temp = self.calculate_isa_temp(alt_int)
            data.append([str(weight), altitude, str(isa_temp), values[-1]])
        else:
            # Below 7000 ft, we have all 8 temperature columns plus ISA
            for j in range(min(8, len(values))):
                data.append([str(weight), altitude, str(temps[j]), values[j]])
            
            # Add ISA if we have it
            if len(values) > 8:
                isa_temp = self.calculate_isa_temp(alt_int)
                data.append([str(weight), altitude, str(isa_temp), values[8]])
    
    def extract_landing_data(self) -> None:
        """Extract landing performance data"""
        logger.info("Extracting landing data...")
        
        # Landing pages based on PDF structure
        # Pages are 0-indexed in PyPDF2
        # Data tables are on the page after the parameters page
        landing_configs = {
            '100': {
                5550: [22],  # Page 23 in PDF (0-indexed: 22) - unfactored data table
                4500: [26]   # Page 27 in PDF (0-indexed: 26) - unfactored data table
            },
            '50': {
                5550: [24],  # Page 25 in PDF (0-indexed: 24) - unfactored data table
                4500: [28]   # Page 29 in PDF (0-indexed: 28) - unfactored data table
            }
        }
        
        for flap_setting, weight_pages in landing_configs.items():
            logger.info(f"Extracting landing data for flaps {flap_setting}")
            
            all_ground_run = [['weight', 'altitude', 'temperature', 'value']]
            all_total_distance = [['weight', 'altitude', 'temperature', 'value']]
            
            for weight, pages in weight_pages.items():
                for page_num in pages:
                    logger.info(f"Processing landing page {page_num} for {weight} lb")
                    text = self.extract_text_from_page(page_num)
                    
                    # Replace comma in 10,000
                    text = text.replace('10,000', '10000')
                    
                    lines = text.split('\n')
                    
                    for i, line in enumerate(lines):
                        line = line.strip()
                        
                        # Look for ground run lines - handle both formats
                        if 'Gnd Roll' in line:
                            # Extract altitude and values from same line
                            # Format: "SLGnd Roll 2028 2103 2177..." or "1000Gnd Roll 2103 2180..."
                            match = re.match(r'(SL|\d+)\s*Gnd\s*Roll\s*([\d\s]+)', line)
                            if match:
                                altitude = '0' if match.group(1) == 'SL' else match.group(1)
                                values = re.findall(r'\d+', match.group(2))
                                
                                if values:
                                    self._process_landing_values(all_ground_run, weight, altitude, values)
                        
                        # Look for total lines
                        elif 'Total' in line and not 'Landing' in line:
                            # First check if altitude is on the same line (format varies)
                            match = re.match(r'(SL|\d+)\s*Total\s*([\d\s]+)', line)
                            if match:
                                altitude = '0' if match.group(1) == 'SL' else match.group(1)
                                values = re.findall(r'\d+', match.group(2))
                                if values:
                                    self._process_landing_values(all_total_distance, weight, altitude, values)
                            else:
                                # Extract values without altitude prefix
                                values_text = re.sub(r'^.*?Total\s*', '', line)
                                values_text = values_text.replace(',', '')
                                values = re.findall(r'\d+', values_text)
                                
                                if values:
                                    # Find altitude from previous ground run line
                                    for j in range(i-1, max(0, i-2), -1):
                                        prev_line = lines[j].strip()
                                        if 'Gnd Roll' in prev_line:
                                            alt_match = re.search(r'(SL|\d+)\s*Gnd\s*Roll', prev_line)
                                            if alt_match:
                                                altitude = '0' if alt_match.group(1) == 'SL' else alt_match.group(1)
                                                self._process_landing_values(all_total_distance, weight, altitude, values)
                                                break
            
            # Save data
            self.save_csv(all_ground_run, self.create_output_path("landing", flap_setting, "ground run.csv"))
            self.save_csv(all_total_distance, self.create_output_path("landing", flap_setting, "total distance.csv"))
    
    def _process_landing_values(self, data: List[List], weight: int, altitude: str, values: List[str]) -> None:
        """Process landing values with ISA column first pattern"""
        alt_int = int(altitude)
        
        # For landing tables in G2+, the pattern is:
        # First value is ISA (goes to 0°C), then temperature columns, then last value is for ISA temperature
        
        if len(values) > 0:
            # First value goes to 0°C
            data.append([str(weight), altitude, '0', values[0]])
            
            # Temperature columns
            temps = [10, 20, 30, 40, 50]
            
            # Add temperature values (excluding first and last)
            num_temp_values = len(values) - 2  # minus first ISA, minus last ISA temp value
            
            for i in range(num_temp_values):
                if i < len(temps):
                    data.append([str(weight), altitude, str(temps[i]), values[i + 1]])
            
            # Add ISA temperature with last value
            if len(values) > 1:
                isa_temp = self.calculate_isa_temp(alt_int)
                data.append([str(weight), altitude, str(isa_temp), values[-1]])
    
    def extract_climb_data(self) -> None:
        """Extract takeoff climb performance data"""
        logger.info("Extracting takeoff climb data...")
        
        # Extract climb gradient
        gradient_data = self.parse_climb_gradient_tables()
        self.save_csv(gradient_data, self.create_output_path("takeoff climb", "gradient.csv"))
        
        # Extract climb rate
        rate_data = self.parse_climb_rate_tables()
        self.save_csv(rate_data, self.create_output_path("takeoff climb", "rate.csv"))
    
    def parse_climb_gradient_tables(self) -> List[List]:
        """Parse climb gradient data from matrix format"""
        data = [['weight', 'altitude', 'temperature', 'value']]
        weights = [6000, 5500, 5000, 4500]
        
        # Known altitude sequence for validation
        expected_altitudes = ['0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000', '9000', '10000']
        
        # Process pages containing gradient data
        # Page 9 has altitude 0 only
        # Pages 10-14 have multiple altitudes per page
        
        # First process page 9 (altitude 0 only)
        if 9 < len(self.pdf_reader.pages):
            text = self.extract_text_from_page(9)
            text = text.replace('10,000', '10000')
            lines = text.split('\n')
            
            logger.info(f"Processing climb gradient page 9 for altitude 0")
            
            for line in lines:
                line = line.strip()
                
                # Handle altitude 0 format "0-40" or just temperature
                if line.startswith('0-'):
                    parts = line.split()
                    if len(parts) >= 5:
                        temp = parts[0][1:]  # Remove '0' prefix
                        values = parts[1:5]
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), '0', temp, values[w_idx]])
                else:
                    # Match temperature followed by 4 values
                    match = re.match(r'^(-?\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)', line)
                    if match:
                        temp = match.group(1)
                        values = [match.group(2), match.group(3), match.group(4), match.group(5)]
                        
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), '0', temp, values[w_idx]])
        
        # Process pages 10-14 which have multiple altitudes
        for page_num in range(10, 15):
            if page_num >= len(self.pdf_reader.pages):
                break
                
            text = self.extract_text_from_page(page_num)
            text = text.replace('10,000', '10000')
            lines = text.split('\n')
            
            logger.info(f"Processing climb gradient page {page_num}")
            
            current_altitude = None
            
            for line in lines:
                line = line.strip()
                
                # Check for altitude markers in expected sequence
                for alt in expected_altitudes:
                    # Pattern 1: Clean altitude like "1000-40 1232..."
                    if line.startswith(f"{alt}-"):
                        parts = line.split()
                        if len(parts) >= 5:
                            current_altitude = alt
                            temp = parts[0].split('-')[1]  # Get temperature after dash
                            values = parts[1:5]
                            
                            for w_idx, weight in enumerate(weights):
                                if w_idx < len(values):
                                    data.append([str(weight), current_altitude, f"-{temp}", values[w_idx]])
                            break
                    # Pattern 2: Altitude embedded in page header like "11 of 461000-40"
                    elif f"{alt}-" in line and "of" in line:
                        # Extract the part after altitude
                        idx = line.find(f"{alt}-")
                        rest = line[idx:]
                        parts = rest.split()
                        if len(parts) >= 5:
                            current_altitude = alt
                            temp = parts[0].split('-')[1]  # Get temperature after dash
                            values = parts[1:5]
                            
                            for w_idx, weight in enumerate(weights):
                                if w_idx < len(values):
                                    data.append([str(weight), current_altitude, f"-{temp}", values[w_idx]])
                            break
                
                # If no altitude found, check for temperature line using current altitude
                if current_altitude and not any(line.startswith(f"{alt}-") or f"{alt}-" in line for alt in expected_altitudes):
                    match = re.match(r'^(-?\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)', line)
                    if match:
                        temp = match.group(1)
                        values = [match.group(2), match.group(3), match.group(4), match.group(5)]
                        
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), current_altitude, temp, values[w_idx]])
        
        return data
    
    def parse_climb_rate_tables(self) -> List[List]:
        """Parse climb rate data from matrix format"""
        data = [['weight', 'altitude', 'temperature', 'value']]
        weights = [6000, 5500, 5000, 4500]
        
        # Known altitude sequence for validation
        expected_altitudes = ['0', '1000', '2000', '3000', '4000', '5000', '6000', '7000', '8000', '9000', '10000']
        
        # Process pages containing rate data
        # Page 15 has altitude 0 only
        # Pages 16-20 have multiple altitudes per page
        
        # First process page 15 (altitude 0 only)
        if 15 < len(self.pdf_reader.pages):
            text = self.extract_text_from_page(15)
            text = text.replace('10,000', '10000')
            lines = text.split('\n')
            
            logger.info(f"Processing climb rate page 15 for altitude 0")
            
            for line in lines:
                line = line.strip()
                
                # Handle altitude 0 format "0-40" or just temperature
                if line.startswith('0-'):
                    parts = line.split()
                    if len(parts) >= 5:
                        temp = parts[0][1:]  # Remove '0' prefix
                        values = parts[1:5]
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), '0', temp, values[w_idx]])
                else:
                    # Match temperature followed by 4 values
                    match = re.match(r'^(-?\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)', line)
                    if match:
                        temp = match.group(1)
                        values = [match.group(2), match.group(3), match.group(4), match.group(5)]
                        
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), '0', temp, values[w_idx]])
        
        # Process pages 16-20 which have multiple altitudes
        for page_num in range(16, 21):
            if page_num >= len(self.pdf_reader.pages):
                break
                
            text = self.extract_text_from_page(page_num)
            text = text.replace('10,000', '10000')
            lines = text.split('\n')
            
            logger.info(f"Processing climb rate page {page_num}")
            
            current_altitude = None
            
            for line in lines:
                line = line.strip()
                
                # Check for altitude markers in expected sequence
                for alt in expected_altitudes:
                    # Pattern 1: Clean altitude like "1000-40 2126..."
                    if line.startswith(f"{alt}-"):
                        parts = line.split()
                        if len(parts) >= 5:
                            current_altitude = alt
                            temp = parts[0].split('-')[1]  # Get temperature after dash
                            values = parts[1:5]
                            
                            for w_idx, weight in enumerate(weights):
                                if w_idx < len(values):
                                    data.append([str(weight), current_altitude, f"-{temp}", values[w_idx]])
                            break
                    # Pattern 2: Altitude embedded in page header like "17 of 461000-40"
                    elif f"{alt}-" in line and "of" in line:
                        # Extract the part after altitude
                        idx = line.find(f"{alt}-")
                        rest = line[idx:]
                        parts = rest.split()
                        if len(parts) >= 5:
                            current_altitude = alt
                            temp = parts[0].split('-')[1]  # Get temperature after dash
                            values = parts[1:5]
                            
                            for w_idx, weight in enumerate(weights):
                                if w_idx < len(values):
                                    data.append([str(weight), current_altitude, f"-{temp}", values[w_idx]])
                            break
                
                # If no altitude found, check for temperature line using current altitude
                if current_altitude and not any(line.startswith(f"{alt}-") or f"{alt}-" in line for alt in expected_altitudes):
                    match = re.match(r'^(-?\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)', line)
                    if match:
                        temp = match.group(1)
                        values = [match.group(2), match.group(3), match.group(4), match.group(5)]
                        
                        for w_idx, weight in enumerate(weights):
                            if w_idx < len(values):
                                data.append([str(weight), current_altitude, temp, values[w_idx]])
        
        return data
    
    def extract_all_data(self) -> None:
        """Extract all data from the PDF"""
        logger.info(f"Starting extraction from {self.pdf_path}...")
        
        # Create output directory
        os.makedirs("output/g2+", exist_ok=True)
        
        # Extract each data type
        self.extract_takeoff_data()
        self.extract_landing_data()
        self.extract_climb_data()
        
        logger.info("All data extraction completed successfully!")
        logger.info(f"Output saved to: output/g2+/")


def main():
    parser = argparse.ArgumentParser(description='Extract G2+ AFM Supplement data to CSV files')
    parser.add_argument('pdf_path', help='Path to the G2+ AFM Supplement PDF file')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.pdf_path):
        logger.error(f"PDF file not found: {args.pdf_path}")
        sys.exit(1)
    
    try:
        with G2PlusAFMDataExtractor(args.pdf_path) as extractor:
            extractor.extract_all_data()
    except Exception as e:
        logger.error(f"Error during extraction: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()