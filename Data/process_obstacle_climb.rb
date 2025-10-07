#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/data_processor"

# Processes obstacle climb performance data with rate of climb and gradient metrics
class ObstacleClimbProcessor < DataProcessor
  CLIMB_WEIGHTS = [6000, 5500, 5000, 4500].freeze
  CLIMB_METRICS = %w[ROC Grad].freeze

  private

  def setup_configuration
    @climb_weights = CLIMB_WEIGHTS
    @climb_metrics = CLIMB_METRICS
    @weight_metric_pairs = build_weight_metric_pairs
  end

  def default_output_structure
    Hash.new { |h, k| h[k] = [%w[weight altitude temperature value]] }
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

      process_climb_section(section_lines, altitude)
    end
  end

  def process_climb_section(lines, altitude)
    lines.each do |line|
      climb_data = parse_climb_line(line)
      next unless climb_data

      temperature, values = climb_data
      process_climb_values(altitude, temperature, values)
    end
  end

  def parse_climb_line(line)
    values = line.split.map { |v| to_i(v) }
    return nil if values.size <= 1

    temperature = values.shift
    [temperature, values]
  end

  def process_climb_values(altitude, temperature, values)
    @weight_metric_pairs.each_with_index do |(weight, metric), index|
      @output[metric] << [weight, altitude, temperature, values[index]]
    end
  end

  # Builds alternating pairs of [weight, metric] for the column mapping
  def build_weight_metric_pairs
    pairs = []
    @climb_weights.each do |weight|
      @climb_metrics.each do |metric|
        pairs << [weight, metric]
      end
    end
    pairs
  end

  public

  def print_output
    @climb_metrics.each_with_index do |metric, index|
      puts @output[metric].map(&:to_csv).join
      puts "------------------" unless index == @climb_metrics.length - 1
    end
  end
end

# Execute if run directly
if __FILE__ == $PROGRAM_NAME
  processor = ObstacleClimbProcessor.new
  processor.process.print_output
end
