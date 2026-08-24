import Testing

@testable import Tally

@Suite("Category catalog")
struct CategoryCatalogTests {
    @Test("Expense and income lists are non-empty and distinct")
    func lists() {
        #expect(!CategoryCatalog.expenses.isEmpty)
        #expect(!CategoryCatalog.income.isEmpty)
        #expect(CategoryCatalog.names(for: .expense) == CategoryCatalog.expenses)
        #expect(CategoryCatalog.names(for: .income) == CategoryCatalog.income)
    }

    @Test("Every catalog name has a symbol")
    func symbols() {
        for name in CategoryCatalog.expenses + CategoryCatalog.income {
            #expect(!CategoryCatalog.symbol(for: name).isEmpty)
        }
    }

    @Test("Every seeded transaction uses a category the picker offers")
    func seedCategoriesAreSelectable() {
        for item in Seed.transactions {
            #expect(CategoryCatalog.names(for: item.type).contains(item.category))
        }
    }

    @Test("Seeded transactions all carry a positive amount")
    func seedAmountsPositive() {
        #expect(Seed.transactions.allSatisfy { $0.amount > 0 })
    }

    @Test("Seeded transaction ids are unique")
    func seedIdsUnique() {
        let ids = Set(Seed.transactions.map(\.id))
        #expect(ids.count == Seed.transactions.count)
    }
}
