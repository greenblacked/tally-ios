import Foundation
import Testing

@testable import Tally

@Suite("Undo delete")
@MainActor
struct UndoTests {
    private func makeStore() throws -> (BudgetStore, String) {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        return (BudgetStore(defaults: suite), name)
    }

    @Test("Undo puts the transaction back where it was, not on top")
    func undoRestoresPosition() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        let before = store.transactions
        let target = before[3]
        store.delete(id: target.id)
        #expect(store.transactions.count == before.count - 1)

        store.undoDelete()
        #expect(store.transactions == before)
    }

    @Test("There is nothing to undo until something is deleted")
    func nothingToUndoInitially() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        #expect(store.lastDeleted == nil)
        store.undoDelete()
        #expect(store.transactions.count == Seed.transactions.count)
    }

    @Test("Undo is spent after one use")
    func undoIsSingleShot() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        let target = store.transactions[0]
        store.delete(id: target.id)
        store.undoDelete()
        #expect(store.lastDeleted == nil)

        let restored = store.transactions
        store.undoDelete()
        #expect(store.transactions == restored)
    }

    @Test("Only the most recent delete is offered back")
    func undoTracksTheLatestDelete() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        let first = store.transactions[0]
        let second = store.transactions[1]
        store.delete(id: first.id)
        store.delete(id: second.id)
        #expect(store.lastDeleted?.transaction == second)

        store.undoDelete()
        #expect(store.transactions.contains(second))
        #expect(!store.transactions.contains(first))
    }

    @Test("Deleting an id that is not there changes nothing")
    func deletingUnknownIdIsANoOp() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        let before = store.transactions
        store.delete(id: "no-such-id")
        #expect(store.transactions == before)
        #expect(store.lastDeleted == nil)
    }

    @Test("Clearing the undo drops the pending restore")
    func clearUndoDiscards() throws {
        let (store, name) = try makeStore()
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }

        store.delete(id: store.transactions[0].id)
        #expect(store.lastDeleted != nil)
        store.clearUndo()
        #expect(store.lastDeleted == nil)
    }

    @Test("A restored delete survives a relaunch")
    func undoIsPersisted() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        let store = BudgetStore(defaults: suite)
        let target = store.transactions[2]
        store.delete(id: target.id)
        store.undoDelete()

        #expect(BudgetStore(defaults: suite).transactions.contains(target))
    }
}
