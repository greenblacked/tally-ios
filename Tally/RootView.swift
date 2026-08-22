import SwiftUI

struct RootView: View {
    @Environment(BudgetStore.self) private var store
    @State private var showAdd = false
    @State private var editing: Transaction?

    var body: some View {
        TabView {
            NavigationStack {
                OverviewView(onAdd: { showAdd = true })
            }
            .tabItem { Label("Overview", systemImage: "banknote") }

            NavigationStack {
                ActivityView(onAdd: { showAdd = true }, onEdit: { editing = $0 })
            }
            .tabItem { Label("Activity", systemImage: "list.bullet") }

            NavigationStack {
                CategoriesView(onAdd: { showAdd = true })
            }
            .tabItem { Label("Categories", systemImage: "chart.pie.fill") }
        }
        .tint(Color(red: 0, green: 0.48, blue: 1))
        .sheet(isPresented: $showAdd) {
            TransactionFormView(editing: nil)
        }
        .sheet(item: $editing) { item in
            TransactionFormView(editing: item)
        }
    }
}

struct MonthPicker: View {
    @Environment(BudgetStore.self) private var store

    var body: some View {
        HStack {
            Button {
                store.shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            Button(action: store.jumpToCurrentMonth) {
                Text(Month.date(from: store.selectedMonth), format: .dateTime.month(.wide).year())
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 160)
            }
            .buttonStyle(.plain)
            Button {
                store.shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
        }
        .foregroundStyle(Color(red: 0, green: 0.48, blue: 1))
    }
}

struct CategoryGlyph: View {
    var name: String

    var body: some View {
        Image(systemName: CategoryCatalog.symbol(for: name))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(CategoryCatalog.color(for: name), in: Circle())
    }
}
