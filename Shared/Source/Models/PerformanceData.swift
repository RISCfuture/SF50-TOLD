import Foundation
import CSV

class PerformanceData {
    let takeoffGroundRoll: Table
    let takeoffOverObstacle: Table
    
    let landingGroundRoll: Table
    let landingOverObstacle: Table
    
    init() {
        takeoffGroundRoll = load(path: dataFile("takeoff - ground roll")!)
        takeoffOverObstacle = load(path: dataFile("takeoff - total")!)
        
        landingGroundRoll = load(path: dataFile("landing - ground roll")!, dimensions: 2)
        landingOverObstacle = load(path: dataFile("landing - total")!, dimensions: 2)
    }
}

fileprivate func load(path: URL, dimensions: UInt = 3) -> Table {
    let csv = try! CSVReader(stream: InputStream(url: path)!)
    let table = Table(dimensions: dimensions)
    
    while let row = csv.next() {
        table.add(values: row.map { Double($0)! })
    }
    
    return table
}

fileprivate func dataFile(_ name: String) -> URL? {
    return Bundle.main.url(forResource: name, withExtension: "csv", subdirectory: "SR22 Data")
}
