import Foundation
import CSV

class PerformanceData {
    let takeoffGroundRoll: Table
    let takeoffOverObstacle: Table
    
    let landingGroundRoll_flaps100: Table
    let landingGroundRoll_flaps50: Table
    let landingGroundRoll_flaps50Ice: Table
    let landingOverObstacle_flaps100: Table
    let landingOverObstacle_flaps50: Table
    let landingOverObstacle_flaps50Ice: Table
    
    let vref_flaps50Ice: Table
    let vref_flaps50: Table
    let vref_flaps100: Table
    let vref_flapsUp: Table
    
    init() {
        takeoffGroundRoll = load(path: dataFile("takeoff distance - ground roll")!)
        takeoffOverObstacle = load(path: dataFile("takeoff distance - total")!)
        
        landingGroundRoll_flaps100 = load(path: dataFile("landing distance - ground roll - flaps 100")!)
        landingGroundRoll_flaps50 = load(path: dataFile("landing distance - ground roll - flaps 50")!)
        landingGroundRoll_flaps50Ice = load(path: dataFile("landing distance - ground roll - flaps 50 ice")!)
        landingOverObstacle_flaps100 = load(path: dataFile("landing distance - total - flaps 100")!)
        landingOverObstacle_flaps50 = load(path: dataFile("landing distance - total - flaps 50")!)
        landingOverObstacle_flaps50Ice = load(path: dataFile("landing distance - total - flaps 50 ice")!)
        
        vref_flaps50Ice = load(path: dataFile("vref 50 ice")!, dimensions: 2)
        vref_flaps50 = load(path: dataFile("vref 50")!, dimensions: 2)
        vref_flaps100 = load(path: dataFile("vref 100")!, dimensions: 2)
        vref_flapsUp = load(path: dataFile("vref up")!, dimensions: 2)
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
    return Bundle.main.url(forResource: name, withExtension: "csv", subdirectory: "SF50 Data")
}
