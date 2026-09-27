import Foundation
import Testing

@testable import Tally

@Suite("Currency")
struct CurrencyTests {
    @Test("Every selectable code formats and names itself")
    func selectableCodesAreUsable() {
        for code in Money.selectableCodes {
            #expect(!Money.format(1234.5, code: code).isEmpty)
            #expect(!Money.symbol(for: code).isEmpty)
            #expect(!Money.name(for: code).isEmpty)
        }
    }

    @Test("Codes are unique and include the fallback")
    func codeList() {
        #expect(Set(Money.selectableCodes).count == Money.selectableCodes.count)
        #expect(Money.selectableCodes.contains(Money.fallbackCurrencyCode))
    }

    @Test("Different currencies produce different output")
    func codeChangesOutput() {
        #expect(Money.format(10, code: "USD") != Money.format(10, code: "JPY"))
    }

    @Test("The symbol never leaks digits or separators")
    func symbolIsSymbolOnly() {
        for code in Money.selectableCodes {
            let symbol = Money.symbol(for: code)
            #expect(!symbol.contains(where: \.isNumber))
            #expect(!symbol.contains("."))
            #expect(!symbol.contains(","))
        }
    }

    @MainActor
    @Test("A chosen currency survives a relaunch")
    func currencyPersists() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        let store = BudgetStore(defaults: suite)
        store.setCurrency("EUR")
        #expect(store.currencyCode == "EUR")
        #expect(BudgetStore(defaults: suite).currencyCode == "EUR")
    }

    @MainActor
    @Test("With no stored preference the device's currency wins")
    func defaultsToDeviceCurrency() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        let expected = Locale.current.currency?.identifier ?? Money.fallbackCurrencyCode
        #expect(BudgetStore(defaults: suite).currencyCode == expected)
    }

    @MainActor
    @Test("Formatting through the store uses the chosen currency")
    func storeFormatsWithChosenCurrency() throws {
        let name = "tally.tests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        defer { suite.removePersistentDomain(forName: name) }

        let store = BudgetStore(defaults: suite)
        store.setCurrency("GBP")
        #expect(store.money(12.5) == Money.format(12.5, code: "GBP"))
        #expect(store.currencySymbol == Money.symbol(for: "GBP"))
    }
}
