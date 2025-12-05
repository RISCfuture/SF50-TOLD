import Defaults
import SF50_Shared
import SwiftUI

struct ClimbConfigView: View {
  @Environment(ClimbPerformanceViewModel.self)
  private var performance

  @Environment(\.aircraftType)
  private var aircraftType

  @Default(.fuelVolumeUnit)
  private var fuelVolumeUnit

  @Default(.heightUnit)
  private var heightUnit

  @Default(.temperatureUnit)
  private var temperatureUnit

  private var limitations: any Limitations.Type {
    aircraftType.limitations
  }

  private var fuelStep: Measurement<UnitVolume> {
    // 10 gallons or 30 liters
    switch fuelVolumeUnit {
      case .liters:
        return Measurement(value: 30, unit: .liters)
      default:
        return Measurement(value: 10, unit: .gallons)
    }
  }

  private var altitudeStep: Measurement<UnitLength> {
    // 500 feet or 200 meters
    switch heightUnit {
      case .meters:
        return Measurement(value: 200, unit: .meters)
      default:
        return Measurement(value: 500, unit: .feet)
    }
  }

  private var temperatureStep: Measurement<UnitTemperature> {
    // 5°C or 10°F
    switch temperatureUnit {
      case .fahrenheit:
        return Measurement(value: 10, unit: .fahrenheit)
      default:
        return Measurement(value: 5, unit: .celsius)
    }
  }

  private var fuelBinding: Binding<Double> {
    Binding(
      get: { performance.fuel.converted(to: UnitVolume.baseUnit()).value },
      set: { performance.fuel = Measurement(value: $0, unit: UnitVolume.baseUnit()) }
    )
  }

  private var altitudeBinding: Binding<Double> {
    Binding(
      get: { performance.altitude.converted(to: UnitLength.baseUnit()).value },
      set: { performance.altitude = Measurement(value: $0, unit: UnitLength.baseUnit()) }
    )
  }

  private var ISADeviationBinding: Binding<Double> {
    Binding(
      get: { performance.ISADeviation.converted(to: UnitTemperature.baseUnit()).value },
      set: { performance.ISADeviation = Measurement(value: $0, unit: UnitTemperature.baseUnit()) }
    )
  }

  // ISA temperature at current altitude
  private var ISATemperature: Measurement<UnitTemperature> {
    let altitudeFeet = performance.altitude.converted(to: .feet).value
    let isaTemp = 15.0 - (1.98 * altitudeFeet / 1000.0)
    return Measurement(value: isaTemp, unit: .celsius)
  }

  // Min/max values rounded to nearest step
  private var minFuel: Measurement<UnitVolume> {
    Measurement(value: 0, unit: fuelVolumeUnit)
  }

  private var maxFuel: Measurement<UnitVolume> {
    let step = fuelStep.converted(to: .gallons).value
    let rounded = (limitations.maxFuel.value / step).rounded() * step
    return Measurement(value: rounded, unit: .gallons)
  }

  private var minAltitude: Measurement<UnitLength> {
    Measurement(value: 0, unit: heightUnit)
  }

  private var maxAltitude: Measurement<UnitLength> {
    let step = altitudeStep.converted(to: .feet).value
    let rounded = (limitations.maxEnrouteAltitude.value / step).rounded() * step
    return Measurement(value: rounded, unit: .feet)
  }

  private var minISADeviation: Measurement<UnitTemperature> {
    let step = temperatureStep.converted(to: .celsius).value
    let rounded = (-40.0 / step).rounded() * step
    return Measurement(value: rounded, unit: .celsius)
  }

  private var maxISADeviation: Measurement<UnitTemperature> {
    let step = temperatureStep.converted(to: .celsius).value
    let rounded = (35.0 / step).rounded() * step
    return Measurement(value: rounded, unit: .celsius)
  }

  var body: some View {
    @Bindable var performance = performance

    Section {
      // Fuel slider
      VStack(alignment: .leading) {
        LabeledContent("Fuel Remaining") {
          Text(performance.fuel.converted(to: fuelVolumeUnit), format: .fuel)
            .fontWeight(.semibold)
            .id(fuelVolumeUnit)
        }

        let fuelParams = validatedSliderRange(
          min: minFuel,
          max: maxFuel,
          step: fuelStep
        )
        Slider(
          value: fuelBinding,
          in: fuelParams.range,
          step: fuelParams.step
        ) {
          Text("Fuel Remaining")
        } minimumValueLabel: {
          Text(minFuel.converted(to: fuelVolumeUnit), format: .fuel)
            .id(fuelVolumeUnit)
        } maximumValueLabel: {
          Text(maxFuel.converted(to: fuelVolumeUnit), format: .fuel)
            .id(fuelVolumeUnit)
        }
        .accessibilityIdentifier("climbFuelSlider")
      }

      // Altitude slider
      VStack(alignment: .leading) {
        LabeledContent("Altitude") {
          Text(performance.altitude.converted(to: heightUnit), format: .height)
            .fontWeight(.semibold)
            .id(heightUnit)
        }

        let altitudeParams = validatedSliderRange(
          min: minAltitude,
          max: maxAltitude,
          step: altitudeStep
        )
        Slider(
          value: altitudeBinding,
          in: altitudeParams.range,
          step: altitudeParams.step
        ) {
          Text("Altitude")
        } minimumValueLabel: {
          Text(minAltitude.converted(to: heightUnit), format: .height)
            .id(heightUnit)
        } maximumValueLabel: {
          Text(maxAltitude.converted(to: heightUnit), format: .height)
            .id(heightUnit)
        }
        .accessibilityIdentifier("climbAltitudeSlider")
      }

      // ISA Deviation slider
      VStack(alignment: .leading) {
        LabeledContent("OAT (ISA Deviation)") {
          let OAT = performance.OAT.converted(to: temperatureUnit)
          let deviation = performance.ISADeviation.converted(to: temperatureUnit)

          Text(
            "\(OAT, format: .temperature) (ISA\(deviation.value, format: .temperature.sign(strategy: .always())))"
          )
          .fontWeight(.semibold)
          .id(temperatureUnit)
        }

        let ISAParams = validatedSliderRange(
          min: minISADeviation,
          max: maxISADeviation,
          step: temperatureStep
        )
        Slider(
          value: ISADeviationBinding,
          in: ISAParams.range,
          step: ISAParams.step
        ) {
          Text("ISA Deviation")
        } minimumValueLabel: {
          Text(minISADeviation.converted(to: temperatureUnit), format: .temperature(plusSign: true))
            .id(temperatureUnit)
        } maximumValueLabel: {
          Text(maxISADeviation.converted(to: temperatureUnit), format: .temperature(plusSign: true))
            .id(temperatureUnit)
        }
        .accessibilityIdentifier("climbISADeviationSlider")
      }

      // IPS toggle
      Toggle("Engine IPS", isOn: $performance.iceProtection)
        .accessibilityIdentifier("climbIceProtectionToggle")
    }
  }

  private func validatedSliderRange<UnitType: Dimension>(
    min: Measurement<UnitType>,
    max: Measurement<UnitType>,
    step: Measurement<UnitType>
  ) -> (range: ClosedRange<Double>, step: Double) {
    let baseUnit = UnitType.baseUnit()
    let minValue = min.converted(to: baseUnit).value
    let maxValue = max.converted(to: baseUnit).value

    // For temperature, convert the step as a difference, not an absolute value
    let stepValue: Double =
      if step.unit is UnitTemperature {
        abs(
          step.unit.converter.baseUnitValue(fromValue: step.value)
            - step.unit.converter.baseUnitValue(fromValue: 0)
        )
      } else {
        step.converted(to: baseUnit).value
      }

    // Ensure step is positive (SwiftUI requirement)
    guard stepValue > 0 else {
      return (minValue...minValue, 0.01)
    }

    // Ensure max > min (SwiftUI requirement)
    guard maxValue > minValue else {
      return (minValue...(minValue + stepValue), stepValue)
    }

    return (minValue...maxValue, stepValue)
  }
}

#Preview("Imperial Units") {
  PreviewView { preview in
    return List { ClimbConfigView() }
      .environment(ClimbPerformanceViewModel(container: preview.container))
  }
}

#Preview("Metric Units") {
  PreviewView { preview in
    preview.useMetricUnits()

    return List { ClimbConfigView() }
      .environment(ClimbPerformanceViewModel(container: preview.container))
  }
}
