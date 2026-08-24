import Foundation
import Testing

@testable import Tally

private func tx(
    _ id: String,
    _ type: TxType,
    _ amount: Double,
    _ category: String,
    _ date: String
) -> Transaction {
    Transaction(id: id, type: type, amount: amount, category: category, note: "", date: date)
}

@Suite("Monthly summary")
struct SummaryTests {
    private let ledger: [Transaction] = [
        tx("a", .income, 4800, "Salary", "2026-08-01"),
        tx("b", .expense, 1850, "Housing", "2026-08-01"),
        tx("c", .expense, 150, "Food", "2026-08-12"),
        tx("d", .expense, 100, "Food", "2026-08-14"),
        tx("e", .income, 500, "Freelance", "2026-07-20"),
        tx("f", .expense, 90, "Transport", "2026-07-21"),
    ]

    @Test("Only the requested month is included")
    func filtersByMonth() {
        let august = Month.summarize(ledger, month: "2026-08")
        #expect(august.items.count == 4)
        #expect(august.items.allSatisfy { $0.date.hasPrefix("2026-08") })
    }

    @Test("Income, expenses, and remaining add up")
    func totals() {
        let august = Month.summarize(ledger, month: "2026-08")
        #expect(august.income == 4800)
        #expect(august.expenses == 2100)
        #expect(august.remaining == 2700)
    }

    @Test("Income never appears in the category breakdown")
    func slicesExcludeIncome() {
        let august = Month.summarize(ledger, month: "2026-08")
        #expect(!august.slices.contains { $0.name == "Salary" })
    }

    @Test("Same-category expenses are merged into one slice")
    func slicesMergeCategories() {
        let august = Month.summarize(ledger, month: "2026-08")
        let food = august.slices.first { $0.name == "Food" }
        #expect(food?.value == 250)
    }

    @Test("Slices are ordered largest first")
    func slicesSortedDescending() {
        let august = Month.summarize(ledger, month: "2026-08")
        let values = august.slices.map(\.value)
        #expect(values == values.sorted(by: >))
    }

    @Test("Slice shares sum to the whole")
    func sharesSumToOne() {
        let august = Month.summarize(ledger, month: "2026-08")
        let total = august.slices.reduce(0) { $0 + $1.share }
        #expect(abs(total - 1) < 0.0001)
    }

    @Test("A month with no expenses produces no NaN shares")
    func incomeOnlyMonthHasNoNaN() {
        let summary = Month.summarize([tx("a", .income, 10, "Salary", "2026-09-01")], month: "2026-09")
        #expect(summary.expenses == 0)
        #expect(summary.slices.isEmpty)
        #expect(summary.remaining == 10)
    }

    @Test("An empty month is all zeroes, not a crash")
    func emptyMonth() {
        let summary = Month.summarize(ledger, month: "2030-01")
        #expect(summary.items.isEmpty)
        #expect(summary.income == 0)
        #expect(summary.expenses == 0)
        #expect(summary.remaining == 0)
        #expect(summary.slices.isEmpty)
    }

    @Test("Spending more than you earn leaves a negative remainder")
    func overspending() {
        let summary = Month.summarize(
            [tx("a", .income, 100, "Salary", "2026-10-01"), tx("b", .expense, 250, "Food", "2026-10-02")],
            month: "2026-10"
        )
        #expect(summary.remaining == -150)
    }

    @Test("Items come back newest day first")
    func itemsSortedNewestFirst() {
        let august = Month.summarize(ledger, month: "2026-08")
        let dates = august.items.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }
}
