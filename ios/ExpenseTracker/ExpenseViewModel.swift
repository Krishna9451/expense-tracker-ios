import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class ExpenseViewModel {
    var isSyncing = false
    var statusMessage: String?

    private let api: ExpenseAPI

    init(api: ExpenseAPI = APIService()) {
        self.api = api
    }

    func add(title: String, amount: Double, category: ExpenseCategory, date: Date, context: ModelContext) {
        context.insert(Expense(title: title, amount: amount, category: category, date: date))
        try? context.save()
    }

    func markEdited(_ expense: Expense, context: ModelContext) {
        expense.isSynced = false
        try? context.save()
    }

    func delete(_ expense: Expense, context: ModelContext) async {
        let id = expense.id
        context.delete(expense)
        try? context.save()
        // Best effort: if offline, the server copy is removed on a later session.
        try? await api.delete(id: id)
    }

    /// Push unsynced local changes, then pull any server expenses we don't have yet.
    func sync(local: [Expense], context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            for expense in local where !expense.isSynced {
                try await api.upsert(expense.dto)
                expense.isSynced = true
            }
            let remote = try await api.fetchExpenses()
            let knownIDs = Set(local.map(\.id))
            for dto in remote where !knownIDs.contains(dto.id) {
                context.insert(Expense(dto: dto))
            }
            try context.save()
            statusMessage = "Synced \(remote.count) expense(s)"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
