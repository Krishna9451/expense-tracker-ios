import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case entertainment = "Entertainment"
    case other = "Other"

    var id: String { rawValue }
}

/// Local (SwiftData) model. `isSynced` marks whether the latest version reached the server.
@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var categoryRaw: String
    var date: Date
    var isSynced: Bool

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), title: String, amount: Double,
         category: ExpenseCategory, date: Date = Date(), isSynced: Bool = false) {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.date = date
        self.isSynced = isSynced
    }

    convenience init(dto: ExpenseDTO) {
        self.init(id: dto.id, title: dto.title, amount: dto.amount,
                  category: ExpenseCategory(rawValue: dto.category) ?? .other,
                  date: dto.date, isSynced: true)
    }

    var dto: ExpenseDTO {
        ExpenseDTO(id: id, title: title, amount: amount, category: categoryRaw, date: date)
    }
}
