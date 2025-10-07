#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/data_processor"

# Processes takeoff and landing distance data with altitude and temperature variations
class DistanceProcessor < DataProcessor
  DISTANCE_TYPES = ["Gnd Roll", "Total"].freeze
  STANDARD_WEIGHTS = [4500].freeze
  TEMPERATURE_COLUMNS = [0, 10, 20, 30, 40, 50, :isa].freeze

  private

  def setup_configuration
    @distance_types = DISTANCE_TYPES
    @standard_weights = STANDARD_WEIGHTS
    @temperature_columns = TEMPERATURE_COLUMNS
    @omitted_temperatures = [].freeze # Can be overridden for specific altitude limits
  end

  def parse_input(input)
    input.each_line.map(&:chomp).in_groups_of(3) do |slice|
      process_distance_group(slice)
    end
  end

  def process_distance_group(slice)
    # Parse the three-line groups: [distance_type, altitude, distance_type]
    distance_data = parse_distance_rows(slice)
    altitude = transform_altitude(distance_data[:altitude])

    available_temps = determine_available_temperatures(altitude)

    available_temps.each_with_index do |temp_column, index|
      @distance_types.each do |distance_type|
        next unless distance_data[distance_type]

        @output[distance_type] << [
            *@standard_weights,
            altitude,
            transform_temperature(temp_column, altitude),
            distance_data[distance_type][index]
        ]
      end
    end
  end

  def parse_distance_rows(slice)
    rows = {}

    slice.each do |line|
      if @distance_types.any? { |type| line.start_with?(type) }
        type = @distance_types.find { |t| line.start_with?(t) }
        rows[type] = line.delete_prefix(type).split.map { |v| to_i(v) }
      elsif line.match?(/^\d+|SL$/)
        rows[:altitude] = line
      end
    end

    rows
  end

  def determine_available_temperatures(altitude)
    omitted_limit = @omitted_temperatures.reverse_each.
        find { |(alt, _)| alt <= altitude }&.last

    return @temperature_columns unless omitted_limit

    @temperature_columns.select { |temp| temp == :isa || temp < omitted_limit }
  end

  public

  def print_output
    @distance_types.each_with_index do |type, index|
      puts @output[type].map(&:to_csv).join
      puts "-------" unless index == @distance_types.length - 1
    end
  end
end

# Execute if run directly
if __FILE__ == $PROGRAM_NAME
  processor = DistanceProcessor.new
  processor.process.print_output
end
