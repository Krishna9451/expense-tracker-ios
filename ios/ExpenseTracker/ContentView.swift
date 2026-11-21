import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var viewModel = ExpenseViewModel()
    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var category: ExpenseCategory?
    @State private var range: TimeRange = .all

    private var filtered: [Expense] {
        ExpenseCalculator.filter(expenses, category: category, range: range)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total spent").font(.caption).foregroundStyle(.secondary)
                        Text(ExpenseCalculator.total(filtered), format: .currency(code: "INR"))
                            .font(.largeTitle.bold())
                    }
                    Picker("Period", selection: $range) {
                        ForEach(TimeRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Category", selection: $category) {
                        Text("All categories").tag(ExpenseCategory?.none)
                        ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag(ExpenseCategory?.some($0)) }
                    }
                }

                Section("Expenses") {
                    if filtered.isEmpty {
                        ContentUnavailableView("No expenses", systemImage: "indianrupeesign.circle",
                                               description: Text("Tap + to add your first one."))
                    }
                    ForEach(filtered) { expense in
                        Button { editing = expense } label: { row(expense) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let items = offsets.map { filtered[$0] }
                        Task { for item in items { await viewModel.delete(item, context: context) } }
                    }
                }

                if let message = viewModel.statusMessage {
                    Section { Text(message).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    NavigationLink { ExpenseChartView() } label: { Image(systemName: "chart.bar.xaxis") }
                    Button {
                        Task { await viewModel.sync(local: expenses, context: context) }
                    } label: {
                        if viewModel.isSyncing { ProgressView() } else { Image(systemName: "arrow.triangle.2.circlepath") }
                    }
                    .disabled(viewModel.isSyncing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ExpenseFormView(expense: nil, viewModel: viewModel)
            }
            .sheet(item: $editing) { expense in
                ExpenseFormView(expense: expense, viewModel: viewModel)
            }
        }
    }

    private func row(_ expense: Expense) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title).font(.headline)
                Text("\(expense.category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: "INR"))
                if !expense.isSynced {
                    Image(systemName: "icloud.slash").font(.caption2).foregroundStyle(.orange)
                }
            }
        }
    }
}
