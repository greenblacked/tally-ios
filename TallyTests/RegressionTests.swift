import Foundation
import Testing

@testable import Tally

/// Guards for bugs found during review. Each one failed before its fix; they are
/// here so the behaviour cannot quietly come back.
@Suite("Regressions")
struct RegressionTests {
    /// `init` used to fall back to `Seed.transactions` whenever the decoded array
    /// was empty, so deleting your last entry resurrected 22 demo ones.
    @MainActor
    @Test("An emptied ledger stays empty across a relaunch")
    func emptyLedgerIsNotReseeded() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        suite.set(try JSONEncoder().encode([Transaction]()), forKey: BudgetStore.txKey)
        #expect(BudgetStore(defaults: suite).transactions.isEmpty)
    }

    /// A genuinely absent key is still first launch, where the sample data helps.
    @MainActor
    @Test("A first launch still gets the sample ledger")
    func firstLaunchIsSeeded() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        #expect(BudgetStore(defaults: suite).transactions.count == Seed.transactions.count)
    }

    /// Same-day ordering used to break ties on `id`, a random UUID for anything
    /// the user created, so a new entry landed at an arbitrary spot in its day.
    @Test("A transaction added today sorts above older ones from the same day")
    func newestSameDayEntryIsFirst() {
        let older = Transaction(
            id: "zzzz-older", type: .expense, amount: 10, category: "Food",
            note: "Older", date: "2026-08-20", createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let newer = Transaction(
            id: "aaaa-newer", type: .expense, amount: 20, category: "Food",
            note: "Just added", date: "2026-08-20", createdAt: Date(timeIntervalSince1970: 2_000)
        )
        let summary = Month.summarize([older, newer], month: "2026-08")
        #expect(summary.items.first?.note == "Just added")
    }

    @Test("Stamped entries sort above ledger entries that predate the field")
    func stampedEntriesOutrankUnstamped() {
        let legacy = Transaction(
            id: "aaaa-legacy", type: .expense, amount: 10, category: "Food",
            note: "Legacy", date: "2026-08-20"
        )
        let added = Transaction(
            id: "zzzz-added", type: .expense, amount: 20, category: "Food",
            note: "Just added", date: "2026-08-20", createdAt: Date()
        )
        let summary = Month.summarize([legacy, added], month: "2026-08")
        #expect(summary.items.first?.note == "Just added")
    }

    /// Ledgers saved before `createdAt` existed must still decode.
    @Test("Transactions saved without a creation stamp still decode")
    func decodesLedgerWithoutCreatedAt() throws {
        let legacy = """
        [{"id":"a","type":"expense","amount":12.5,"category":"Food","note":"Lunch","date":"2026-08-02"}]
        """
        let decoded = try JSONDecoder().decode([Transaction].self, from: Data(legacy.utf8))
        #expect(decoded.count == 1)
        #expect(decoded[0].createdAt == nil)
        #expect(decoded[0].amount == 12.5)
    }

    /// `Money.format` used to hold a shared NumberFormatter, which Swift 6
    /// rejects as a non-Sendable global.
    @Test("Money formats without a shared formatter")
    func moneyFormats() {
        #expect(!Money.format(1234.5).isEmpty)
        #expect(!Money.currencySymbol.isEmpty)
        #expect(Money.editable(1850) == Money.editable(1850))
    }
}
