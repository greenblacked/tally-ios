import SwiftUI

enum AppTab: Hashable {
    case overview
    case activity
    case categories
}

struct RootView: View {
    @State private var tab: AppTab = .overview
    @State private var showAdd = false
    @State private var editing: Transaction?

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "banknote", value: .overview) {
                NavigationStack {
                    OverviewView(onAdd: { showAdd = true })
                }
            }
            Tab("Activity", systemImage: "list.bullet", value: .activity) {
                NavigationStack {
                    ActivityView(onAdd: { showAdd = true }, onEdit: { editing = $0 })
                }
            }
            Tab("Categories", systemImage: "chart.pie.fill", value: .categories) {
                NavigationStack {
                    CategoriesView(onAdd: { showAdd = true })
                }
            }
        }
        .tint(Color.tallyAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
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
            .accessibilityLabel("Previous month")
            Button {
                store.jumpToCurrentMonth()
            } label: {
                Text(Month.date(from: store.selectedMonth), format: .dateTime.month(.wide).year())
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Jumps to the current month")
            Button {
                store.shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Color.tallyAccent)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected month")
    }
}

struct CategoryGlyph: View {
    var name: String

    var body: some View {
        Image(systemName: CategoryCatalog.symbol(for: name))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(CategoryCatalog.color(for: name), in: Circle())
            .accessibilityHidden(true)
    }
}

struct AddToolbarButton: View {
    var action: () -> Void

    var body: some View {
        Button("Add", systemImage: "plus", action: action)
            .accessibilityLabel("Add transaction")
    }
}
