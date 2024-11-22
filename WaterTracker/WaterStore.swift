import Foundation
import SwiftUI

@MainActor
class WaterStore: ObservableObject {
    @Published var waterIntake: Double = 0
    @Published var dailyGoal: Double = 67.6 // 2L in fluid ounces
    @Published var records: [WaterRecord] = []
    
    private let healthKitManager = HealthKitManager()
    private let userDefaults = UserDefaults.standard
    private let waterIntakeKey = "WaterIntake"
    private let recordsKey = "WaterRecords"
    
    init() {
        loadData()
        Task {
            await healthKitManager.requestAuthorization()
            await syncWithHealthKit()
        }
    }
    
    private func loadData() {
        waterIntake = userDefaults.double(forKey: waterIntakeKey)
        if let savedRecords = userDefaults.data(forKey: recordsKey),
           let decodedRecords = try? JSONDecoder().decode([WaterRecord].self, from: savedRecords) {
            records = decodedRecords
        }
        
        // Check if we need to reset for a new day
        if let lastRecord = records.first {
            if !Calendar.current.isDate(lastRecord.date, inSameDayAs: Date()) {
                resetWater()
            }
        }
    }
    
    private func saveData() {
        userDefaults.set(waterIntake, forKey: waterIntakeKey)
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }
    
    func addWater(_ amount: Double) {
        waterIntake += amount
        updateTodayRecord()
        saveData()
        
        // Sync with HealthKit
        Task {
            await healthKitManager.saveWaterIntake(amount: amount)
        }
    }
    
    func subtractWater(_ amount: Double) {
        waterIntake = max(0, waterIntake - amount)
        updateTodayRecord()
        saveData()
        
        // For HealthKit, we'll sync the total
        Task {
            await syncWithHealthKit()
        }
    }
    
    func resetWater() {
        waterIntake = 0
        updateTodayRecord()
        saveData()
        
        // For HealthKit, we'll let the existing data stay
        // as it might be useful for historical tracking
    }
    
    private func updateTodayRecord() {
        let today = Date()
        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            records[index].amount = waterIntake
        } else {
            records.insert(WaterRecord(date: today, amount: waterIntake), at: 0)
        }
        
        // Keep only last 30 days
        if records.count > 30 {
            records.removeLast(records.count - 30)
        }
    }
    
    private func syncWithHealthKit() async {
        // Fetch today's total from HealthKit
        let healthKitTotal = await healthKitManager.fetchTodayWaterIntake()
        
        // If HealthKit has more water logged than our app, update our app
        if healthKitTotal > waterIntake {
            await MainActor.run {
                waterIntake = healthKitTotal
                updateTodayRecord()
                saveData()
            }
        }
    }
    
    func getDailyAverage() -> Double {
        guard !records.isEmpty else { return 0 }
        let sum = records.reduce(0) { $0 + $1.amount }
        return sum / Double(records.count)
    }
    
    func getWeeklyAverage() -> Double {
        let lastWeekRecords = getLastWeekRecords()
        guard !lastWeekRecords.isEmpty else { return 0 }
        let sum = lastWeekRecords.reduce(0) { $0 + $1.amount }
        return sum / Double(lastWeekRecords.count)
    }
    
    func getLastWeekRecords() -> [WaterRecord] {
        let calendar = Calendar.current
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }
        return records.filter { $0.date >= oneWeekAgo }
    }
}
