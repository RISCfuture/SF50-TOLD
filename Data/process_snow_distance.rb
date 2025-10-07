#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/data_processor"

# Processes snow contamination distance data for landing performance
class SnowDistanceProcessor < DataProcessor
  SNOW_TYPES = {
      slush_wet: {header: %w[distance depth value], depths: ->(d) { d != "dry" && d != "1.0" && d != "compact" }},
      dry:       {header: %w[distance value], depths: ->(d) { d == "1.0" }},
      compact:   {header: %w[distance value], depths: ->(d) { d == "compact" }}
  }.freeze

  private

  def setup_configuration
    @snow_outputs = SNOW_TYPES.transform_values { |config| [config[:header]] }
  end

  def default_output_structure
    # Override to use our custom structure
    @snow_outputs
  end

  def parse_input(input)
    lines = input.split("\n").map { it.chomp.split }
    header_depths = lines.shift
    distance_rows = lines.map { |row| row.map { |v| to_i(v) } }

    process_snow_data(header_depths, distance_rows)
  end

  def process_snow_data(header_depths, distance_rows)
    distance_rows.each do |row|
      base_distance = row.first

      header_depths.each_with_index do |depth, index|
        categorize_snow_depth(base_distance, depth, row[index])
      end
    end
  end

  def categorize_snow_depth(base_distance, depth, value)
    SNOW_TYPES.each do |snow_type, config|
      next unless config[:depths].call(depth)

      row_data = build_snow_row(base_distance, depth, value, config)
      @snow_outputs[snow_type] << row_data
      break # Each depth should only match one category
    end
  end

  def build_snow_row(base_distance, depth, value, config)
    case config[:header].size
      when 2 # distance, value (dry and compact snow)
        [base_distance, value]
      when 3 # distance, depth, value (slush/wet snow)
        [base_distance, depth, value]
    end
  end

  public

  def print_output
    snow_type_order = %i[slush_wet dry compact]

    snow_type_order.each_with_index do |snow_type, index|
      @snow_outputs[snow_type].each { |row| puts row.to_csv }
      puts "-------" unless index == snow_type_order.length - 1
    end
  end
end

# Execute if run directly
if __FILE__ == $PROGRAM_NAME
  processor = SnowDistanceProcessor.new
  processor.process.print_output
end
