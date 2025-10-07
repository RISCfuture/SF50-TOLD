#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/data_processor"

# Processes wet runway distance data with varying contamination depths
class WetDistanceProcessor < DataProcessor
  private

  def default_output_structure
    [%w[distance depth value]]
  end

  def parse_input(input)
    lines = input.split("\n").map { it.chomp.split }
    header_depths = parse_header_depths(lines.shift)
    distance_rows = lines.map { |row| row.map { |v| to_i(v) } }

    process_wet_data(header_depths, distance_rows)
  end

  def parse_header_depths(header_row)
    # Convert "Dry" to 0.0, other values to float
    header_row.map { |depth| (depth == "Dry") ? 0.0 : Float(depth) }
  end

  def process_wet_data(header_depths, distance_rows)
    distance_rows.each do |row|
      base_distance = row.first

      header_depths.each_with_index do |depth, index|
        @output << [base_distance, depth, row[index]]
      end
    end
  end

  public

  def print_output
    puts @output.map(&:to_csv).join
  end
end

# Execute if run directly
if __FILE__ == $PROGRAM_NAME
  processor = WetDistanceProcessor.new
  processor.process.print_output
end
