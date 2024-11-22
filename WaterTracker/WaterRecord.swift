import Foundation

struct WaterRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let amount: Double // in fluid ounces
    
    init(date: Date = Date(), amount: Double) {
        self.id = UUID()
        self.date = date
        self.amount = amount
    }
}
