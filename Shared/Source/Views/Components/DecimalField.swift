// swiftlint:disable file_header
//  DecimalField.swift
//
//  Created by Edwin Watkeys on 9/20/19.
//  Copyright © 2019 Edwin Watkeys.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import Combine
import SwiftUI

struct DecimalField : View {
    let label: LocalizedStringKey
    @Binding var value: Double
    let formatter: NumberFormatter
    let suffix: String?
    let minimum: Double?
    let maximum: Double?
    let onEditingChanged: (Bool) -> Void
    let onCommit: () -> Void

    // The formatter that formats the editing string.
    private let editStringFormatter: NumberFormatter

    // The text shown by the wrapped TextField. This is also the "source of
    // truth" for the `value`.
    @State private var textValue: String = "" {
        didSet {
            guard self.hasInitialTextValue else {
                // We don't have a usable `textValue` yet -- bail out.
                return
            }
            // This is the only place we update `value`.
            let num = self.formatter.number(from: textValue)
            self.valid = self.isValid(number: num)
            if let value = num?.doubleValue { self.value = value }
        }
    }

    // When the view loads, `textValue` is not synced with `value`.
    // This flag ensures we don't try to get a `value` out of `textValue`
    // before the view is fully initialized.
    @State private var hasInitialTextValue = false

    @State private var valid = true

    var body: some View {
        HStack(spacing: 0) {
            TextField("", text: $textValue, onEditingChanged: { isInFocus in
                // When the field is in focus we replace the field's contents
                // with a plain specifically formatted number. When not in focus, the field
                // is treated as a label and shows the formatted value.
                if isInFocus {
                    let newValue = formatter.number(from: textValue)
                    valid = isValid(number: newValue)
                    textValue = editStringFormatter.string(for: newValue) ?? ""
                } else {
                    let f = formatter
                    let newValue = f.number(from: textValue)
                    valid = isValid(number: newValue)
                    textValue = f.string(for: newValue) ?? ""
                }
                onEditingChanged(isInFocus)
            }, onCommit: {
                hideKeyboard()
                onCommit()
            })
            .onAppear { // Otherwise textfield is empty when view appears
                hasInitialTextValue = true
                // Any `textValue` from this point on is considered valid and
                // should be synced with `value`.

                // Synchronize `textValue` with `value`; can't be done earlier
                textValue = formatter.string(from: NSDecimalNumber(value: value)) ?? ""
            }
            .onChange(of: value) { _, value in
                textValue = formatter.string(from: NSDecimalNumber(value: value)) ?? ""
            }
            .decimalField()
            .foregroundColor(valid ? .primary : .red)

            if let suffix {
                Text(verbatim: " \(suffix)").foregroundColor(.secondary)
            }
        }
    }

    init(
        _ label: LocalizedStringKey,
        value: Binding<Double>,
        formatter: NumberFormatter,
        suffix: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {}
    ) {
        self.label = label
        self._value = value
        self.formatter = formatter
        self.suffix = suffix
        self.minimum = minimum
        self.maximum = maximum
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit

        // We configure the edit string formatter to behave like the
        // input formatter without add the currency symbol,
        // percent symbol, etc...
        self.editStringFormatter = NumberFormatter()
        self.editStringFormatter.allowsFloats = formatter.allowsFloats
        self.editStringFormatter.alwaysShowsDecimalSeparator = formatter.alwaysShowsDecimalSeparator
        self.editStringFormatter.decimalSeparator = formatter.decimalSeparator
        self.editStringFormatter.maximumIntegerDigits = formatter.maximumIntegerDigits
        self.editStringFormatter.maximumSignificantDigits = formatter.maximumSignificantDigits
        self.editStringFormatter.maximumFractionDigits = formatter.maximumFractionDigits
        self.editStringFormatter.multiplier = formatter.multiplier
    }

    private func isValid(number: NSNumber?) -> Bool {
        guard let num = number?.doubleValue else { return false }
        if let minimum {
            if num < minimum { return false }
        }
        if let maximum {
            if num > maximum { return false }
        }
        return true
    }
}

#Preview {
    struct TipCalculator: View {
        @State private var amount = 50.0
        @State private var tipRate = 0.1

        var tipValue: Double {
            return amount * tipRate
        }

        var totalValue: Double {
            return amount + tipValue
        }

        static var currencyFormatter: NumberFormatter {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.isLenient = true
            return nf
        }

        static var percentFormatter: NumberFormatter {
            let nf = NumberFormatter()
            nf.numberStyle = .percent
            nf.isLenient = true
            return nf
        }

        var body: some View {
            Form {
                Section {
                    DecimalField("Amount", value: $amount, formatter: Self.currencyFormatter)
                    DecimalField("Tip Rate", value: $tipRate, formatter: Self.percentFormatter)
                }
                Section {
                    HStack {
                        Text("Tip Amount")
                        Spacer()
                        Text(Self.currencyFormatter.string(for: tipValue)!)
                    }
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(Self.currencyFormatter.string(for: totalValue)!)
                    }
                }
            }
        }
    }

    return TipCalculator()
}

// swiftlint:enable file_header
