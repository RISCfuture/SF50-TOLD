#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/data_processor"

# Processes takeoff climb performance data for various aircraft weights
class TakeoffClimbProcessor < DataProcessor
  TAKEOFF_WEIGHTS = [6000, 5500, 5000, 4500].freeze

  private

  def setup_configuration
    @takeoff_weights = TAKEOFF_WEIGHTS
    @weight_exclusions = {}.freeze # altitude => { temp => [excluded_weights] }
  end

  def default_output_structure
    [%w[weight altitude temperature value]]
  end

  def parse_input(input)
    altitude_sections = parse_altitude_sections(input)
    process_altitude_sections(input, altitude_sections)
  end

  def process_altitude_sections(input, sections)
    input_lines = input.each_line.to_a
    line_offset = 0

    sections.each do |row_count, altitude|
      section_lines = input_lines[line_offset, row_count].map(&:chomp)
      line_offset += row_count

      process_takeoff_section(section_lines, altitude)
    end
  end

  def process_takeoff_section(lines, altitude)
    lines.each do |line|
      takeoff_data = parse_takeoff_line(line)
      next unless takeoff_data

      temperature, values = takeoff_data
      process_takeoff_values(altitude, temperature, values)
    end
  end

  def parse_takeoff_line(line)
    values = line.split.map { |v| to_i(v) }
    return nil if values.size <= 1

    temperature = values.shift
    [temperature, values]
  end

  def process_takeoff_values(altitude, temperature, values)
    available_weights = determine_available_weights(altitude, temperature)

    available_weights.each_with_index do |weight, index|
      @output << [weight, altitude, temperature, values[index]]
    end
  end

  def determine_available_weights(altitude, temperature)
    excluded = @weight_exclusions.dig(altitude, temperature) || []
    @takeoff_weights.excluding(*excluded)
  end

  public

  def print_output
    puts @output.map(&:to_csv).join
  end
end

# Execute if run directly
if __FILE__ == $PROGRAM_NAME
  processor = TakeoffClimbProcessor.new
  processor.process.print_output
end
