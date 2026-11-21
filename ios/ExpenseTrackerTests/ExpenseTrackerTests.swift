import XCTest
import SwiftData
@testable import ExpenseTracker

final class ExpenseCalculatorTests: XCTestCase {
    private func make(_ title: String, _ amount: Double, _ category: ExpenseCategory, daysAgo: Int = 0) -> Expense {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Expense(title: title, amount: amount, category: category, date: date)
    }

    func testTotal() {
        let items = [make("a", 100, .food), make("b", 50.5, .bills)]
        XCTAssertEqual(ExpenseCalculator.total(items), 150.5, accuracy: 0.001)
    }

    func testTotalsByCategoryAreSortedDescending() {
        let items = [make("a", 10, .food), make("b", 90, .bills), make("c", 20, .food)]
        let totals = ExpenseCalculator.totalsByCategory(items)
        XCTAssertEqual(totals.map(\.category), [.bills, .food])
        XCTAssertEqual(totals.last?.total ?? 0, 30, accuracy: 0.001)
    }

    func testFilterByCategory() {
        let items = [make("a", 10, .food), make("b", 90, .bills)]
        let result = ExpenseCalculator.filter(items, category: .food, range: .all)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "a")
    }

    func testFilterByLastSevenDays() {
        let items = [make("recent", 10, .food, daysAgo: 2), make("old", 10, .food, daysAgo: 30)]
        let result = ExpenseCalculator.filter(items, category: nil, range: .week)
        XCTAssertEqual(result.map(\.title), ["recent"])
    }
}

final class MockAPI: ExpenseAPI {
    var upserted: [ExpenseDTO] = []
    var remote: [ExpenseDTO] = []
    var shouldFail = false

    func fetchExpenses() async throws -> [ExpenseDTO] {
        if shouldFail { throw APIError.server(500) }
        return remote
    }
    func upsert(_ expense: ExpenseDTO) async throws {
        if shouldFail { throw APIError.server(500) }
        upserted.append(expense)
    }
    func delete(id: UUID) async throws {}
}

@MainActor
final class ExpenseViewModelTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(for: Expense.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return container.mainContext
    }

    func testSyncPushesUnsyncedAndPullsRemote() async throws {
        let context = try makeContext()
        let local = Expense(title: "Local", amount: 10, category: .food)
        context.insert(local)

        let api = MockAPI()
        api.remote = [ExpenseDTO(id: UUID(), title: "Remote", amount: 5, category: "Bills", date: Date())]
        let viewModel = ExpenseViewModel(api: api)

        await viewModel.sync(local: [local], context: context)

        XCTAssertTrue(local.isSynced)
        XCTAssertEqual(api.upserted.count, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 2)
    }

    func testSyncFailureKeepsExpenseUnsyncedAndReportsError() async throws {
        let context = try makeContext()
        let local = Expense(title: "Local", amount: 10, category: .food)
        context.insert(local)

        let api = MockAPI()
        api.shouldFail = true
        let viewModel = ExpenseViewModel(api: api)

        await viewModel.sync(local: [local], context: context)

        XCTAssertFalse(local.isSynced)
        XCTAssertNotNil(viewModel.statusMessage)
    }
}
