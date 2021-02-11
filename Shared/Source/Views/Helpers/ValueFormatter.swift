import Foundation

func numberFormatter(precision: UInt = 0, minimum: Double? = 0, maximum: Double? = nil) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.generatesDecimalNumbers = true
    formatter.roundingMode = .halfUp
    formatter.roundingIncrement = pow(10, -Double(precision)) as NSNumber
    formatter.minimumFractionDigits = Int(precision)
    formatter.maximumFractionDigits = Int(precision)
    formatter.allowsFloats = precision != 0
    formatter.minimum = minimum as NSNumber?
    formatter.maximum = maximum as NSNumber?
    formatter.locale = .current
    return formatter
}

class ValueFormatter {
    let precision: UInt
    let minimum: Double?
    let maximum: Double?
    
    var forView: Shim { Shim(self) }
    
    private var rounder: NSDecimalNumberHandler {
        .init(roundingMode: .plain, scale: Int16(precision), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
    }
    private var numberFormatter: NumberFormatter {
        SF50_TOLD.numberFormatter(precision: precision, minimum: minimum, maximum: maximum)
    }
    
    required init(precision: UInt = 0, minimum: Double? = 0, maximum: Double? = nil) {
        self.precision = precision
        self.minimum = minimum
        self.maximum = maximum
    }
    
    func string(for num: Double) -> String {
        let rounded = NSDecimalNumber(value: num).rounding(accordingToBehavior: rounder)
        return numberFormatter.string(for: rounded) ?? rounded.stringValue
    }
    
    func string(for num: Int) -> String {
        let rounded = NSDecimalNumber(value: num).rounding(accordingToBehavior: rounder)
        return numberFormatter.string(for: rounded) ?? rounded.stringValue
    }
    
    func string(for num: UInt) -> String {
        let rounded = NSDecimalNumber(value: num).rounding(accordingToBehavior: rounder)
        return numberFormatter.string(for: rounded) ?? rounded.stringValue
    }
    
    func value(for string: String) -> Double? {
        if string.isEmpty { return nil }
        guard let num = numberFormatter.number(from: string) else { return nil }
        let rounded = (num as! NSDecimalNumber).rounding(accordingToBehavior: rounder)
        return rounded.doubleValue
    }
    
    class Shim: Formatter {
        private let valueFormatter: ValueFormatter
        
        init(_ formatter: ValueFormatter) {
            valueFormatter = formatter
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func string(for obj: Any?) -> String? {
            if let num = obj as? NSDecimalNumber {
                return valueFormatter.string(for: num.doubleValue)
            } else if let num = obj as? NSNumber {
                return valueFormatter.string(for: num.intValue)
            } else {
                return nil
            }
        }
    }
}

var integerFormatter = ValueFormatter()
