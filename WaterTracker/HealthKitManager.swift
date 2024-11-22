import Foundation
import HealthKit
import UIKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    
    init() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async {
        guard isHealthKitAvailable else { return }
        
        let waterType = HKQuantityType(.dietaryWater)
        
        do {
            try await healthStore.requestAuthorization(
                toShare: [waterType],
                read: [waterType]
            )
            await MainActor.run {
                isAuthorized = true
            }
        } catch {
            print("Error requesting HealthKit authorization: \(error)")
        }
    }
    
    func saveWaterIntake(amount: Double, date: Date = Date()) async {
        guard isAuthorized else { return }
        
        let waterType = HKQuantityType(.dietaryWater)
        let flOzUnit = HKUnit.fluidOunceUS()
        let quantity = HKQuantity(unit: flOzUnit, doubleValue: amount)
        let sample = HKQuantitySample(type: waterType,
                                    quantity: quantity,
                                    start: date,
                                    end: date)
        
        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving water intake to HealthKit: \(error)")
        }
    }
    
    func fetchTodayWaterIntake() async -> Double {
        guard isAuthorized else { return 0 }
        
        let waterType = HKQuantityType(.dietaryWater)
        let flOzUnit = HKUnit.fluidOunceUS()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        do {
            let statistics = try await healthStore.statistics(
                for: waterType,
                predicate: predicate
            )
            
            return statistics.sumQuantity()?.doubleValue(for: flOzUnit) ?? 0
        } catch {
            print("Error fetching water intake from HealthKit: \(error)")
            return 0
        }
    }
    
    func fetchWeekWaterIntake() async -> [Date: Double] {
        guard isAuthorized else { return [:] }
        
        let waterType = HKQuantityType(.dietaryWater)
        let flOzUnit = HKUnit.fluidOunceUS()
        let calendar = Calendar.current
        
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return [:]
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: calendar.startOfDay(for: oneWeekAgo),
            end: Date(),
            options: .strictStartDate
        )
        
        let interval = DateComponents(day: 1)
        
        do {
            let collection = try await healthStore.statisticsCollection(
                for: waterType,
                predicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: oneWeekAgo),
                intervalComponents: interval
            )
            
            var results: [Date: Double] = [:]
            collection.enumerateStatistics(from: oneWeekAgo, to: Date()) { statistics, _ in
                let value = statistics.sumQuantity()?.doubleValue(for: flOzUnit) ?? 0
                results[statistics.startDate] = value
            }
            
            return results
            
        } catch {
            print("Error fetching weekly water intake from HealthKit: \(error)")
            return [:]
        }
    }
}
