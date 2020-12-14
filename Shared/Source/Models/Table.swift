class Table {
    var data: Array<Array<Double>>
    let dimensions: UInt
    
    init(dimensions: UInt) {
        data = Array<Array<Double>>()
        self.dimensions = dimensions
    }
    
    func add(values: Array<Double>) {
        guard values.count == dimensions else { fatalError("Incorrect length for values array") }
        data.append(values)
    }
    
    func interpolate(dimensions: Array<Double>, data: Array<Array<Double>>? = nil) -> Interpolation {
        if dimensions.isEmpty { fatalError("Not enough dimensions specified") }
        let dimensionValue = dimensions[0]
        let data = data ?? self.data
        
        guard let lowMatchingValue = data.map({ $0[0] }).last(where: { $0 < dimensionValue }) else { return .offscaleLow }
        guard let highMatchingValue = data.map({ $0[0] }).first(where: { $0 > dimensionValue }) else { return .offscaleHigh }
        
        let lowMatchingRow = data.firstIndex(where: { $0[0] == lowMatchingValue })!
        let highMatchingRow = data.lastIndex(where: { $0[0] == highMatchingValue })!
        let matchingRange = lowMatchingRow...highMatchingRow
        
        let low = data[lowMatchingRow][0]
        let offset = dimensionValue - low
        let factor = 1.0 + offset/low
        
        var matchingData = data.enumerated().reduce(into: Array<Array<Double>>()) { result, row in
            guard matchingRange.contains(row.0) else { return }
            
            var newRow = Array<Double>(row.1[row.1.index(after: row.1.startIndex)...])
            for (i, value) in newRow.enumerated() {
                newRow[i] = (i == row.1.count - 1) ? value*factor : value
            }
            
            result.append(newRow)
        }
        matchingData.sort { $0[0] < $1[0] }
        
        if dimensions.count == 1 {
            let interpolation = matchingData.reduce(0) { sum, row in sum + row[0] } / Double(matchingData.count)
            return .value(interpolation)
        } else {
            let remainingDimensions = Array(dimensions[dimensions.index(after: dimensions.startIndex)...])
            return interpolate(dimensions: remainingDimensions, data: matchingData)
        }
    }
}
