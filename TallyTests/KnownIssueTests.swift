import Foundation
import Testing

@testable import Tally

/// Reproductions for bugs found during review. These are expected to be red
/// until the corresponding fix lands; each one names the behaviour it wants.
@Suite("Known issues", .serialized)
@MainActor
struct KnownIssueTests {
    /// `BudgetStore.init` falls back to `Seed.transactions` whenever the decoded
    /// array is empty, so a user who deletes their last transaction gets 22
    /// fabricated ones back on the next launch.
    @Test("Deleting every transaction stays deleted across a relaunch")
    func emptyLedgerIsNotReseeded() {
        let defaults = UserDefaults.standard
        let key = "tally.transactions"
        let backup = defaults.data(forKey: key)
        defer {
            if let backup { defaults.set(backup, forKey: key) } else { defaults.removeObject(forKey: key) }
        }

        // Simulate a user who has deleted everything.
        defaults.set(try! JSONEncoder().encode([Transaction]()), forKey: key)

        let relaunched = BudgetStore()
        #expect(relaunched.transactions.isEmpty)
    }

    /// `Month.summarize` breaks same-day ties on `id`, which is a random UUID
    /// for anything the user adds, so a new entry lands at an arbitrary spot
    /// inside its day instead of on top.
    @Test("A transaction added today sorts above older ones from the same day")
    func newestSameDayEntryIsFirst() {
        let existing = Transaction(
            id: "zzzz-existing", type: .expense, amount: 10,
            category: "Food", note: "Older", date: "2026-08-20"
        )
        let added = Transaction(
            id: "aaaa-added", type: .expense, amount: 20,
            category: "Food", note: "Just added", date: "2026-08-20"
        )
        let summary = Month.summarize([existing, added], month: "2026-08")
        #expect(summary.items.first?.note == "Just added")
    }
}
