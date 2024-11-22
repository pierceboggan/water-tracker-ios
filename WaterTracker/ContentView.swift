import SwiftUI

struct ContentView: View {
    @EnvironmentObject var waterStore: WaterStore
    @State private var showingAddSheet = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: min(waterStore.waterIntake / waterStore.dailyGoal, 1))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text(String(format: NSLocalizedString("%d fl oz", comment: "Current water intake"), Int(waterStore.waterIntake)))
                            .font(.title)
                            .bold()
                        Text(String(format: NSLocalizedString("of %d fl oz", comment: "Daily goal"), Int(waterStore.dailyGoal)))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(height: 200)
                
                // Quick Add/Subtract Buttons
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        QuickAddButton(amount: 8, action: { waterStore.addWater(8) })
                        QuickAddButton(amount: 16, action: { waterStore.addWater(16) })
                    }
                    HStack(spacing: 20) {
                        QuickSubtractButton(amount: 8, action: { waterStore.subtractWater(8) })
                        QuickSubtractButton(amount: 16, action: { waterStore.subtractWater(16) })
                    }
                }
                
                Spacer()
            }
            .navigationTitle(NSLocalizedString("Water Tracker", comment: "App title"))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                    Button(action: { showingResetAlert = true }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(NSLocalizedString("Reset Water Count", comment: "Reset alert title"), isPresented: $showingResetAlert) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
                Button(NSLocalizedString("Reset", comment: "Reset button"), role: .destructive) {
                    waterStore.resetWater()
                }
            } message: {
                Text(NSLocalizedString("Are you sure you want to reset your water count for today?", comment: "Reset confirmation message"))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWaterView(isPresented: $showingAddSheet)
        }
    }
}

struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("+\(amount)")
                    .font(.headline)
                Text(NSLocalizedString("fl oz", comment: "Fluid ounces abbreviation"))
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

struct QuickSubtractButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("-\(amount)")
                    .font(.headline)
                Text(NSLocalizedString("fl oz", comment: "Fluid ounces abbreviation"))
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(10)
        }
    }
}

struct AddWaterView: View {
    @EnvironmentObject var waterStore: WaterStore
    @Binding var isPresented: Bool
    @State private var amount: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Add Water", comment: "Add water section header"))) {
                    TextField(NSLocalizedString("Amount (fl oz)", comment: "Amount input placeholder"), text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(NSLocalizedString("Add", comment: "Add button")) {
                        if let value = Double(amount) {
                            waterStore.addWater(value)
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Add Water", comment: "Add water view title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                isPresented = false
            })
        }
    }
}
