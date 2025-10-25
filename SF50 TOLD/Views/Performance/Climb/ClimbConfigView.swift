import Defaults
import SF50_Shared
import SwiftUI

struct ClimbConfigView: View {
  @Environment(ClimbPerformanceViewModel.self)
  private var performance

  @Default(.fuelVolumeUnit)
  private var fuelVolumeUnit

  @Default(.heightUnit)
  private var heightUnit

  @Default(.temperatureUnit)
  private var temperatureUnit

  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  private var limitations: any Limitations.Type {
    updatedThrustSchedule ? LimitationsG2Plus.self : LimitationsG1.self
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
      get: { performance.fuel.converted(to: .gallons).value },
      set: { performance.fuel = Measurement(value: $0, unit: .gallons) }
    )
  }

  private var altitudeBinding: Binding<Double> {
    Binding(
      get: { performance.altitude.converted(to: .feet).value },
      set: { performance.altitude = Measurement(value: $0, unit: .feet) }
    )
  }

  private var ISADeviationBinding: Binding<Double> {
    Binding(
      get: { performance.ISADeviation.converted(to: .celsius).value },
      set: { performance.ISADeviation = Measurement(value: $0, unit: .celsius) }
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

        Slider(
          value: fuelBinding,
          in: minFuel.value...maxFuel.value,
          step: fuelStep.converted(to: .gallons).value
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

        Slider(
          value: altitudeBinding,
          in: minAltitude.value...maxAltitude.value,
          step: altitudeStep.converted(to: .feet).value
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

        Slider(
          value: ISADeviationBinding,
          in: minISADeviation.value...maxISADeviation.value,
          step: temperatureStep.converted(to: .celsius).value
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
