import Foundation
import Observation
import SwiftUI

enum TxType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Transaction: Identifiable, Codable, Equatable {
    var id: String
    var type: TxType
    var amount: Double
    var category: String
    var note: String
    var date: String
    /// When the entry was created, used to order entries that share a calendar
    /// day. Optional so ledgers saved before this field existed still decode;
    /// those sort after anything stamped.
    var createdAt: Date?

    init(
        id: String,
        type: TxType,
        amount: Double,
        category: String,
        note: String,
        date: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
        self.createdAt = createdAt
    }
}

struct CategorySlice: Identifiable {
    var id: String { name }
    var name: String
    var value: Double
    var color: Color
    var share: Double
}

struct MonthSummary {
    var items: [Transaction]
    var income: Double
    var expenses: Double
    var remaining: Double
    var slices: [CategorySlice]
}

@MainActor
@Observable
final class BudgetStore {
    var transactions: [Transaction]
    var savingsGoal: Double
    var selectedMonth: String

    private let defaults: UserDefaults
    static let txKey = "tally.transactions"
    static let goalKey = "tally.goal"

    /// - Parameter defaults: injectable so tests can use their own suite instead
    ///   of writing into the real app's storage.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // An empty ledger is a state the user chose by deleting everything, not a
        // signal to reload sample data. Only an absent key means "first launch".
        if let data = defaults.data(forKey: Self.txKey),
           let saved = try? JSONDecoder().decode([Transaction].self, from: data)
        {
            transactions = saved
        } else {
            transactions = Seed.transactions
        }
        let storedGoal = defaults.double(forKey: Self.goalKey)
        savingsGoal = storedGoal > 0 ? storedGoal : Seed.goal
        selectedMonth = Month.current
    }

    var summary: MonthSummary {
        Month.summarize(transactions, month: selectedMonth)
    }

    func add(_ draft: Transaction) {
        transactions.insert(draft, at: 0)
        persist()
    }

    func update(_ draft: Transaction) {
        guard let index = transactions.firstIndex(where: { $0.id == draft.id }) else { return }
        transactions[index] = draft
        persist()
    }

    func delete(id: String) {
        transactions.removeAll { $0.id == id }
        persist()
    }

    func setGoal(_ amount: Double) {
        savingsGoal = amount
        persist()
    }

    func shiftMonth(_ delta: Int) {
        selectedMonth = Month.shift(selectedMonth, by: delta)
    }

    func jumpToCurrentMonth() {
        selectedMonth = Month.current
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(transactions) {
            defaults.set(data, forKey: Self.txKey)
        }
        defaults.set(savingsGoal, forKey: Self.goalKey)
    }
}

extension Color {
    /// The green used for income throughout the app.
    static let income = Color(red: 0.20, green: 0.78, blue: 0.35)
    /// The app's accent, matching AccentColor in the asset catalog.
    static let tallyAccent = Color(red: 0, green: 0.48, blue: 1)
}

enum CategoryCatalog {
    static let expenses = [
        "Housing", "Food", "Transport", "Utilities", "Health",
        "Entertainment", "Shopping", "Subscriptions", "Other",
    ]
    static let income = [
        "Salary", "Freelance", "Investments", "Gifts", "Other income",
    ]

    static func names(for type: TxType) -> [String] {
        type == .income ? income : expenses
    }

    static func symbol(for name: String) -> String {
        switch name {
        case "Housing": "house.fill"
        case "Food": "fork.knife"
        case "Transport": "car.fill"
        case "Utilities": "bolt.fill"
        case "Health": "heart.fill"
        case "Entertainment": "ticket.fill"
        case "Shopping": "bag.fill"
        case "Subscriptions": "arrow.triangle.2.circlepath"
        case "Salary": "briefcase.fill"
        case "Freelance": "laptopcomputer"
        case "Investments": "chart.line.uptrend.xyaxis"
        case "Gifts": "gift.fill"
        default: "ellipsis"
        }
    }

    static func color(for name: String) -> Color {
        switch name {
        case "Housing": Color(red: 0.39, green: 0.82, blue: 1.0)
        case "Food", "Shopping", "Gifts": Color(red: 1.0, green: 0.62, blue: 0.04)
        case "Transport": Color(red: 0.0, green: 0.48, blue: 1.0)
        case "Utilities", "Freelance": Color(red: 0.19, green: 0.69, blue: 0.78)
        case "Health": Color(red: 1.0, green: 0.22, blue: 0.37)
        case "Entertainment": Color(red: 0.39, green: 0.82, blue: 1.0)
        case "Subscriptions": Color(red: 0.19, green: 0.69, blue: 0.78)
        case "Salary", "Investments": Color(red: 0.20, green: 0.78, blue: 0.35)
        default: Color(red: 0.56, green: 0.56, blue: 0.58)
        }
    }
}

enum Month {
    static var current: String { key(from: Date()) }

    static func key(from date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 2026, parts.month ?? 1)
    }

    static func date(from key: String) -> Date {
        let bits = key.split(separator: "-").compactMap { Int($0) }
        return Calendar.current.date(from: DateComponents(year: bits[safe: 0] ?? 2026, month: bits[safe: 1] ?? 1)) ?? Date()
    }

    static func shift(_ key: String, by delta: Int) -> String {
        let start = date(from: key)
        let next = Calendar.current.date(byAdding: .month, value: delta, to: start) ?? start
        return self.key(from: next)
    }

    static func isoDate(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 2026, parts.month ?? 1, parts.day ?? 1)
    }

    static func parseISO(_ iso: String) -> Date {
        let bits = iso.split(separator: "-").compactMap { Int($0) }
        return Calendar.current.date(
            from: DateComponents(year: bits[safe: 0] ?? 2026, month: bits[safe: 1] ?? 1, day: bits[safe: 2] ?? 1)
        ) ?? Date()
    }

    static func defaultDate(for month: String) -> String {
        let today = Date()
        if key(from: today) == month { return isoDate(today) }
        return "\(month)-01"
    }

    static func summarize(_ transactions: [Transaction], month: String) -> MonthSummary {
        let items = transactions
            .filter { $0.date.hasPrefix(month) }
            .sorted {
                guard $0.date == $1.date else { return $0.date > $1.date }
                // Newest first within a day. Entries with no stamp predate the
                // field, so they fall below anything stamped; id keeps it stable.
                switch ($0.createdAt, $1.createdAt) {
                case let (a?, b?) where a != b: return a > b
                case (nil, _?): return false
                case (_?, nil): return true
                default: return $0.id > $1.id
                }
            }
        var income = 0.0
        var expenses = 0.0
        var totals: [String: Double] = [:]
        for item in items {
            if item.type == .income {
                income += item.amount
            } else {
                expenses += item.amount
                totals[item.category, default: 0] += item.amount
            }
        }
        let slices = totals
            .map { CategorySlice(name: $0.key, value: $0.value, color: CategoryCatalog.color(for: $0.key), share: expenses > 0 ? $0.value / expenses : 0) }
            .sorted { $0.value > $1.value }
        return MonthSummary(items: items, income: income, expenses: expenses, remaining: income - expenses, slices: slices)
    }
}

enum Money {
    /// The ledger's currency. Still fixed, but named in one place so a future
    /// picker has somewhere to write to.
    static let currencyCode = "USD"

    /// A shared NumberFormatter would be a non-Sendable global, which Swift 6
    /// rejects; the format style is a value type, so there is nothing to share.
    static func format(_ amount: Double, code: String = currencyCode) -> String {
        amount.formatted(.currency(code: code))
    }

    /// The symbol `format` actually prints — "$" in en_US, "$US" in fr_FR.
    /// Derived from a formatted zero rather than `Locale.currencySymbol`, which
    /// would return the reader's own currency and disagree with the amounts.
    static var currencySymbol: String {
        let zero = (0 as Double).formatted(.currency(code: currencyCode))
        let stripped = zero.filter { !$0.isNumber && !$0.isWhitespace && $0 != "." && $0 != "," }
        return stripped.isEmpty ? currencyCode : stripped
    }

    /// Digits only, for prefilling an editable amount field. Uses the locale's
    /// decimal separator, which AmountParser reads back correctly.
    static func editable(_ amount: Double) -> String {
        amount.formatted(.number.precision(.fractionLength(2)).grouping(.never))
    }
}

enum Seed {
    static let goal: Double = 2800
    static let transactions: [Transaction] = [
        .init(id: "seed-jul-salary", type: .income, amount: 4800, category: "Salary", note: "July salary", date: "2026-07-01"),
        .init(id: "seed-jul-rent", type: .expense, amount: 1850, category: "Housing", note: "Rent", date: "2026-07-01"),
        .init(id: "seed-jul-food", type: .expense, amount: 310.20, category: "Food", note: "Groceries", date: "2026-07-12"),
        .init(id: "seed-jul-util", type: .expense, amount: 150, category: "Utilities", note: "Power and water", date: "2026-07-08"),
        .init(id: "seed-jul-transit", type: .expense, amount: 48, category: "Transport", note: "Metro card", date: "2026-07-04"),
        .init(id: "seed-aug-salary", type: .income, amount: 4800, category: "Salary", note: "August salary", date: "2026-08-01"),
        .init(id: "seed-aug-freelance", type: .income, amount: 640, category: "Freelance", note: "Brand site", date: "2026-08-14"),
        .init(id: "seed-aug-rent", type: .expense, amount: 1850, category: "Housing", note: "Rent", date: "2026-08-01"),
        .init(id: "seed-aug-groc-1", type: .expense, amount: 127.43, category: "Food", note: "Groceries", date: "2026-08-03"),
        .init(id: "seed-aug-electric", type: .expense, amount: 82.16, category: "Utilities", note: "Electric", date: "2026-08-05"),
        .init(id: "seed-aug-metro", type: .expense, amount: 49, category: "Transport", note: "Metro card", date: "2026-08-05"),
        .init(id: "seed-aug-pharmacy", type: .expense, amount: 24.80, category: "Health", note: "Pharmacy", date: "2026-08-07"),
        .init(id: "seed-aug-dinner", type: .expense, amount: 68.40, category: "Food", note: "Dinner out", date: "2026-08-08"),
        .init(id: "seed-aug-groc-2", type: .expense, amount: 96.22, category: "Food", note: "Groceries", date: "2026-08-10"),
        .init(id: "seed-aug-coffee", type: .expense, amount: 5.75, category: "Food", note: "Coffee", date: "2026-08-12"),
        .init(id: "seed-aug-netflix", type: .expense, amount: 15.49, category: "Subscriptions", note: "Netflix", date: "2026-08-12"),
        .init(id: "seed-aug-concert", type: .expense, amount: 42, category: "Entertainment", note: "Concert", date: "2026-08-15"),
        .init(id: "seed-aug-shoes", type: .expense, amount: 128, category: "Shopping", note: "Sneakers", date: "2026-08-16"),
        .init(id: "seed-aug-groc-3", type: .expense, amount: 88.10, category: "Food", note: "Groceries", date: "2026-08-18"),
        .init(id: "seed-aug-lyft", type: .expense, amount: 19.60, category: "Transport", note: "Lyft", date: "2026-08-19"),
        .init(id: "seed-aug-lunch", type: .expense, amount: 14.20, category: "Food", note: "Lunch", date: "2026-08-20"),
        .init(id: "seed-aug-internet", type: .expense, amount: 79.99, category: "Utilities", note: "Internet", date: "2026-08-21"),
    ]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
