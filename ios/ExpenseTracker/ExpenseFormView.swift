import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let expense: Expense?
    let viewModel: ExpenseViewModel

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()

    private var amount: Double? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Amount", text: $amountText).keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle(expense == nil ? "New expense" : "Edit expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || amount == nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let expense else { return }
        title = expense.title
        amountText = String(expense.amount)
        category = expense.category
        date = expense.date
    }

    private func save() {
        guard let amount else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        if let expense {
            expense.title = cleanTitle
            expense.amount = amount
            expense.category = category
            expense.date = date
            viewModel.markEdited(expense, context: context)
        } else {
            viewModel.add(title: cleanTitle, amount: amount, category: category, date: date, context: context)
        }
        dismiss()
    }
}
