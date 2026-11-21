import Foundation

struct CategoryTotal: Identifiable, Equatable {
    let category: ExpenseCategory
    let total: Double
    var id: String { category.rawValue }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case all = "All time"
    case week = "Last 7 days"
    case month = "This month"

    var id: String { rawValue }

    func startDate(now: Date = Date(), calendar: Calendar = .current) -> Date? {
        switch self {
        case .all: return nil
        case .week: return calendar.date(byAdding: .day, value: -7, to: now)
        case .month: return calendar.dateInterval(of: .month, for: now)?.start
        }
    }
}

/// Pure functions, easy to unit test.
enum ExpenseCalculator {
    static func total(_ expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    static func totalsByCategory(_ expenses: [Expense]) -> [CategoryTotal] {
        Dictionary(grouping: expenses, by: \.category)
            .map { CategoryTotal(category: $0.key, total: total($0.value)) }
            .sorted { $0.total > $1.total }
    }

    static func filter(_ expenses: [Expense], category: ExpenseCategory?, range: TimeRange,
                       now: Date = Date()) -> [Expense] {
        let start = range.startDate(now: now)
        return expenses.filter { expense in
            (category == nil || expense.category == category) &&
            (start == nil || expense.date >= start!)
        }
    }
}
