# frozen_string_literal: true

require "csv"
require "bundler"
Bundler.require

require "active_support/core_ext/array/grouping"
require "active_support/core_ext/array/access"

# Base class for processing SF50 TOLD data files
class DataProcessor
  def initialize
    @output = default_output_structure
    setup_configuration
  end

  def process(input=ARGF.read)
    parse_input(input)
    self
  end

  def output(type=nil)
    type ? @output[type] : @output
  end

  def print_output
    raise NotImplementedError, "Subclasses must implement print_output"
  end

  protected

  # Subclasses should override these methods
  def default_output_structure
    Hash.new { |h, k| h[k] = [default_csv_header] }
  end

  def default_csv_header
    %w[weight altitude temperature value]
  end

  def setup_configuration
    # Override in subclasses to set up specific configurations
  end

  def parse_input(input)
    raise NotImplementedError, "Subclasses must implement parse_input"
  end

  # Common utility methods
  def to_i(value)
    Integer(value.tr(",", ""))
  end

  def transform_altitude(value)
    (value == "SL") ? 0 : to_i(value)
  end

  def transform_temperature(value, altitude)
    (value == :isa) ? isa_temperature(altitude) : value
  end

  def isa_temperature(altitude_ft)
    15 - (0.0019812 * altitude_ft)
  end

  # Complex parsing logic shared between obstacle_climb and takeoff_climb processors
  def parse_altitude_sections(input)
    sections = []
    current_section = {row_count: 0, altitude: nil, last_temp: nil}

    input.each_line.with_index do |line, _index|
      current_section[:row_count] += 1

      if altitude_line?(line)
        raise "Altitude appeared twice in section" if current_section[:altitude]

        current_section[:altitude] = to_i(line.chomp)
      else
        temp = extract_temperature(line)

        if temperature_reset?(current_section[:last_temp], temp)
          finalize_section(sections, current_section)
          current_section = {row_count: 1, altitude: nil, last_temp: temp}
        else
          current_section[:last_temp] = temp
        end
      end
    end

    sections << [current_section[:row_count], current_section[:altitude]]
    sections
  end

  private

  def altitude_line?(line)
    line.match?(/^[0-9,]+$/)
  end

  def extract_temperature(line)
    to_i(line.split.first)
  end

  def temperature_reset?(last_temp, current_temp)
    last_temp && last_temp > current_temp
  end

  def finalize_section(sections, current_section)
    raise "Altitude never appeared in section" unless current_section[:altitude]

    sections << [current_section[:row_count] - 1, current_section[:altitude]]
  end
end
