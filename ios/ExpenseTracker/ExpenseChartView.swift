import SwiftUI
import SwiftData
import Charts

struct ExpenseChartView: View {
    @Query private var expenses: [Expense]

    var body: some View {
        let totals = ExpenseCalculator.totalsByCategory(expenses)
        VStack {
            if totals.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "chart.bar",
                                       description: Text("Add some expenses to see your spending."))
            } else {
                Chart(totals) { item in
                    BarMark(x: .value("Category", item.category.rawValue),
                            y: .value("Total", item.total))
                        .foregroundStyle(by: .value("Category", item.category.rawValue))
                }
                .frame(height: 280)
                .padding()
                Spacer()
            }
        }
        .navigationTitle("Spending by category")
        .navigationBarTitleDisplayMode(.inline)
    }
}
