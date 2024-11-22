import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var waterStore: WaterStore
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        List {
            Section(NSLocalizedString("Statistics", comment: "Statistics section header")) {
                HStack {
                    Text(NSLocalizedString("Daily Average", comment: "Daily average label"))
                    Spacer()
                    Text(String(format: NSLocalizedString("%.1f fl oz", comment: "Fluid ounces format"), waterStore.getDailyAverage()))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(NSLocalizedString("Weekly Average", comment: "Weekly average label"))
                    Spacer()
                    Text(String(format: NSLocalizedString("%.1f fl oz", comment: "Fluid ounces format"), waterStore.getWeeklyAverage()))
                        .foregroundColor(.gray)
                }
            }
            
            if #available(iOS 16.0, *) {
                Section(NSLocalizedString("Last 7 Days", comment: "Last week section header")) {
                    Chart(waterStore.getLastWeekRecords()) { record in
                        BarMark(
                            x: .value(NSLocalizedString("Date", comment: "Chart date axis"), record.date, unit: .day),
                            y: .value(NSLocalizedString("Amount", comment: "Chart amount axis"), record.amount)
                        )
                        .foregroundStyle(Color.blue.gradient)
                    }
                    .frame(height: 200)
                    .padding(.vertical)
                }
            }
            
            Section(NSLocalizedString("History", comment: "History section header")) {
                ForEach(waterStore.getLastWeekRecords()) { record in
                    HStack {
                        Text(dateFormatter.string(from: record.date))
                        Spacer()
                        Text(String(format: NSLocalizedString("%.1f fl oz", comment: "Fluid ounces format"), record.amount))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Water History", comment: "History view title"))
    }
}
