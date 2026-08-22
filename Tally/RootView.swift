import SwiftUI

enum AppTab: Hashable {
    case overview
    case activity
    case categories
}

struct RootView: View {
    @Environment(BudgetStore.self) private var store
    @State private var tab: AppTab = .overview
    @State private var showAdd = false
    @State private var editing: Transaction?

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "banknote", value: .overview) {
                NavigationStack {
                    OverviewView()
                }
            }
            Tab("Activity", systemImage: "list.bullet", value: .activity) {
                NavigationStack {
                    ActivityView(onAdd: { showAdd = true }, onEdit: { editing = $0 })
                }
            }
            Tab("Categories", systemImage: "chart.pie.fill", value: .categories) {
                NavigationStack {
                    CategoriesView()
                }
            }
        }
        .tint(Color(red: 0, green: 0.48, blue: 1))
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            RemainingAccessory(onAdd: { showAdd = true })
        }
        .sheet(isPresented: $showAdd) {
            TransactionFormView(editing: nil)
        }
        .sheet(item: $editing) { item in
            TransactionFormView(editing: item)
        }
    }
}

struct RemainingAccessory: View {
    @Environment(BudgetStore.self) private var store
    var onAdd: () -> Void

    private var remaining: Double { store.summary.remaining }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Left this month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(Money.format(remaining))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(remaining < 0 ? Color.red : Color.primary)
            }
            Spacer(minLength: 8)
            Button("Add transaction", systemImage: "plus", action: onAdd)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
        .accessibilityElement(children: .contain)
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
